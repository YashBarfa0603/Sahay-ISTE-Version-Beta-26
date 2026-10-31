import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/utils/auth_error_mapper.dart';

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
          _currentUser = user;
          _isLoading = false;
          if (user != null) {
            _isGuest = false;
          }
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
        email: email,
        password: password,
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
        email: email,
        password: password,
        fullName: fullName,
        mobileNumber: mobileNumber,
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
      await _authRepository.updateProfile(fields);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fields['fullName']?.toString(),
          mobileNumber: fields['mobileNumber']?.toString(),
          age: fields['age'] is int ? fields['age'] as int : int.tryParse(fields['age']?.toString() ?? ''),
          state: fields['state']?.toString(),
          district: fields['district']?.toString(),
          occupation: fields['occupation']?.toString(),
          preferredLanguage: fields['preferredLanguage']?.toString(),
          gender: fields['gender']?.toString(),
          residenceType: fields['residenceType']?.toString(),
          profileComplete: fields['profileComplete'] is bool
              ? fields['profileComplete'] as bool
              : _currentUser!.profileComplete,
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
