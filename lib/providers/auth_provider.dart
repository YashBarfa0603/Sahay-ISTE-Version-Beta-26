import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/utils/auth_error_mapper.dart';
import 'package:sahay/utils/auth_strings.dart';

/// Provider managing authentication state, user profile, and guest access.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _profileSubscription;

  UserModel? _currentUser;
  bool _isGuest = false;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _initAuthListener();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileComplete => _currentUser?.profileComplete ?? false;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream initialization
  void _initAuthListener() {
    try {
      _profileSubscription = _authRepository.currentUserProfileStream.listen(
        (user) {
          if (user != null) {
            if (_currentUser != null &&
                _currentUser!.uid == user.uid &&
                _currentUser!.profileComplete &&
                !user.profileComplete) {
              // Preserve completed profile state even if remote Firestore document hasn't synced
              _currentUser = user.copyWith(
                profileComplete: true,
                age: _currentUser!.age,
                state: _currentUser!.state,
                district: _currentUser!.district,
                occupation: _currentUser!.occupation,
                preferredLanguage: _currentUser!.preferredLanguage,
                gender: _currentUser!.gender,
                residenceType: _currentUser!.residenceType,
              );
            } else {
              _currentUser = user;
            }
            _isGuest = false;
          } else {
            _currentUser = null;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('AuthProvider stream error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
      _isLoading = false;
    } catch (e) {
      debugPrint('AuthProvider init exception: $e');
      _isLoading = false;
    }
  }

  // Guest mode
  void enterGuestMode() {
    _isGuest = true;
    _errorMessage = null;
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
    String lang = 'en',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signIn(
        email: email.trim(),
        password: password,
      );
      if (user == null) {
        _isLoading = false;
        _errorMessage = AuthStrings.getMessage('invalid-credential', lang);
        notifyListeners();
        return false;
      }
      _currentUser = user;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    bool consentAccepted = false,
    String consentVersion = '1.0',
    String lang = 'en',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        mobileNumber: mobileNumber.trim(),
        consentAccepted: consentAccepted,
        consentVersion: consentVersion,
      );
      _currentUser = user;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In
  Future<bool> signInWithGoogle({String lang = 'en'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      _isLoading = false;
      if (user == null) {
        // User cancelled quietly
        notifyListeners();
        return false;
      }
      _currentUser = user;
      _isGuest = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  // Password reset
  Future<bool> sendPasswordReset(String email, {String lang = 'en'}) async {
    _errorMessage = null;
    try {
      await _authRepository.sendPasswordReset(email);
      return true;
    } catch (e) {
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> fields, {String lang = 'en'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      try {
        await _authRepository.updateProfile(fields);
      } catch (cloudErr) {
        debugPrint('AuthProvider: cloud updateProfile non-fatal error: $cloudErr');
      }

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fields['fullName']?.toString() ?? _currentUser!.fullName,
          mobileNumber: fields['mobileNumber']?.toString() ?? _currentUser!.mobileNumber,
          age: fields['age'] is int ? fields['age'] as int : int.tryParse(fields['age']?.toString() ?? ''),
          state: fields['state']?.toString() ?? _currentUser!.state,
          district: fields['district']?.toString() ?? _currentUser!.district,
          occupation: fields['occupation']?.toString() ?? _currentUser!.occupation,
          preferredLanguage: fields['preferredLanguage']?.toString() ?? _currentUser!.preferredLanguage,
          gender: fields['gender']?.toString() ?? _currentUser!.gender,
          residenceType: fields['residenceType']?.toString() ?? _currentUser!.residenceType,
          profileComplete: fields['profileComplete'] is bool
              ? fields['profileComplete'] as bool
              : true,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _isGuest = false;
    } catch (e) {
      debugPrint('AuthProvider: signOut error $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete account
  Future<bool> deleteAccount({String lang = 'en'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMapper.mapErrorToMessage(e, lang);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
