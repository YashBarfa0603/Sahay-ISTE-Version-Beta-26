import 'package:sahay/models/user_model.dart';
import 'package:sahay/services/auth_service.dart';
import 'package:sahay/services/user_service.dart';
import 'package:sahay/utils/auth_error_mapper.dart';

/// Repository coordinating authentication and Firestore user profile data.
class AuthRepository {
  final AuthService _authService;
  final UserService _userService;

  AuthRepository({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  // Profile stream
  Stream<UserModel?> get currentUserProfileStream {
    return _authService.authStateChanges.asyncExpand((user) async* {
      if (user == null) {
        yield null;
        return;
      }

      final stub = UserModel(
        uid: user.uid,
        fullName: (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Citizen'),
        email: (user.email ?? '').trim().toLowerCase(),
        mobileNumber: user.phoneNumber ?? '',
        authProvider: 'email',
        profileComplete: false,
        consentVersion: '1.0',
        consentAcceptedAt: DateTime.now(),
      );

      // Yield immediate authenticated user so UI is never left in an unauthenticated or null state
      yield stub;

      try {
        await for (final profile in _userService.profileStream(user.uid)) {
          if (profile != null) {
            yield profile;
          } else {
            yield stub;
          }
        }
      } catch (e) {
        debugPrint('AuthRepository: profileStream error caught: $e');
        yield stub;
      }
    });
  }

  // Current user
  Future<UserModel?> getCurrentUser() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    return await _userService.getProfile(user.uid);
  }

  // Sign up
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    bool consentAccepted = false,
    String consentVersion = '1.0',
  }) async {
    if (!consentAccepted) {
      throw const AuthFailure(
        code: 'consent-required',
        messageKey: 'consent-required',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    dynamic user;
    try {
      user = await _authService.signUpWithEmail(
        email: normalizedEmail,
        password: password,
      );
    } on AuthFailure catch (e) {
      if (e.code == 'email-already-in-use') {
        // Attempt recovery if user was previously created in Auth but profile creation failed
        try {
          final existingAuthUser = await _authService.signInWithEmail(
            email: normalizedEmail,
            password: password,
          );
          if (existingAuthUser != null) {
            final existingProfile = await _userService.getProfile(existingAuthUser.uid);
            if (existingProfile != null) {
              return existingProfile;
            }
            // User exists in Firebase Auth but missing Firestore profile doc: create profile now
            final recoveredUser = UserModel(
              uid: existingAuthUser.uid,
              fullName: fullName.trim(),
              email: normalizedEmail,
              mobileNumber: mobileNumber.trim(),
              authProvider: 'email',
              profileComplete: false,
              consentAcceptedAt: DateTime.now(),
              consentVersion: consentVersion,
            );
            try {
              await _userService.createProfile(recoveredUser);
            } catch (_) {}
            return recoveredUser;
          }
        } catch (_) {
          // If sign in with the supplied password fails, rethrow the original email-already-in-use
        }
      }
      rethrow;
    }

    if (user == null) {
      throw const AuthFailure(
        code: 'signup-failed',
        messageKey: 'signup-failed',
      );
    }

    final newUser = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: normalizedEmail,
      mobileNumber: mobileNumber.trim(),
      authProvider: 'email',
      profileComplete: false,
      consentAcceptedAt: DateTime.now(),
      consentVersion: consentVersion,
    );

    try {
      await _userService.createProfile(newUser);
    } catch (_) {
      // If Firestore profile creation encounters a database or network error,
      // do not leave user unauthenticated; return newUser so session is valid in-memory.
    }
    return newUser;
  }

  // Sign in
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await _authService.signInWithEmail(
      email: normalizedEmail,
      password: password,
    );
    if (user == null) return null;

    UserModel? existingProfile;
    try {
      existingProfile = await _userService.getProfile(user.uid);
    } catch (_) {}

    if (existingProfile != null) {
      return existingProfile;
    }

    // Auto-recovery: If user exists in Firebase Auth but has no Firestore profile doc yet,
    // generate a stub profile so user is never stuck in an unauthenticated loop.
    final stubProfile = UserModel(
      uid: user.uid,
      fullName: (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Citizen'),
      email: (user.email ?? normalizedEmail).trim().toLowerCase(),
      mobileNumber: user.phoneNumber ?? '',
      authProvider: 'email',
      profileComplete: false,
      consentVersion: '1.0',
      consentAcceptedAt: DateTime.now(),
    );

    try {
      await _userService.createProfile(stubProfile);
    } catch (_) {}

    return stubProfile;
  }

  // Google sign in
  Future<UserModel?> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user == null) {
      return null;
    }

    final existingProfile = await _userService.getProfile(user.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    final stubProfile = UserModel(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      mobileNumber: user.phoneNumber ?? '',
      authProvider: 'google',
      profileComplete: false,
      consentVersion: '1.0',
      consentAcceptedAt: DateTime.now(),
    );

    await _userService.createProfile(stubProfile);
    return stubProfile;
  }

  // Password reset
  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AuthFailure(
        code: 'user-not-found',
        messageKey: 'user-not-found',
      );
    }
    await _userService.updateProfile(user.uid, fields);
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _userService.deleteProfile(user.uid);
    await _authService.deleteAuthUser();
  }
}

