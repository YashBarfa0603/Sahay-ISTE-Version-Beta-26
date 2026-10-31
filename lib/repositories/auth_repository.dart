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
    return _authService.authStateChanges.asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _userService.profileStream(user.uid);
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

    final user = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );

    if (user == null) {
      throw const AuthFailure(
        code: 'signup-failed',
        messageKey: 'signup-failed',
      );
    }

    final newUser = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      mobileNumber: mobileNumber.trim(),
      authProvider: 'email',
      profileComplete: false,
      consentAcceptedAt: DateTime.now(),
      consentVersion: consentVersion,
    );

    await _userService.createProfile(newUser);
    return newUser;
  }

  // Sign in
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    if (user == null) return null;
    return await _userService.getProfile(user.uid);
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

