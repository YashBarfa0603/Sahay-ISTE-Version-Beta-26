import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sahay/utils/auth_error_mapper.dart';

/// Authentication service interfacing with Firebase Auth and Google Sign-In.
class AuthService {
  final FirebaseAuth? _injectedAuth;
  final GoogleSignIn? _injectedGoogleSignIn;
  bool _googleSignInInitialized = false;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _injectedAuth = auth,
        _injectedGoogleSignIn = googleSignIn;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _injectedGoogleSignIn ?? GoogleSignIn.instance;

  // Ensure initialization
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _googleSignInInitialized = true;
      } catch (e) {
        debugPrint('GoogleSignIn initialize: $e');
      }
    }
  }

  // Auth stream
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('AuthService: authStateChanges unavailable: $e');
      return const Stream.empty();
    }
  }

  // Current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Email signup
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signUp error code ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    } catch (e) {
      debugPrint('AuthService: unexpected signUp error $e');
      throw const AuthFailure(code: 'unknown-error', messageKey: 'unknown-error');
    }
  }

  // Email login
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: signIn error code ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    } catch (e) {
      debugPrint('AuthService: unexpected signIn error $e');
      throw const AuthFailure(code: 'unknown-error', messageKey: 'unknown-error');
    }
  }

  // Google sign in
  Future<User?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      debugPrint('AuthService: google sign in exception ${e.code}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw const AuthFailure(
        code: 'google-sign-in-failed',
        messageKey: 'google-sign-in-failed',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: firebase auth google error ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('canceled') || str.contains('cancelled')) {
        return null;
      }
      debugPrint('AuthService: unexpected google error $e');
      throw const AuthFailure(code: 'unknown-error', messageKey: 'unknown-error');
    }
  }

  // Password reset
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: password reset error ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    } catch (e) {
      throw const AuthFailure(code: 'unknown-error', messageKey: 'unknown-error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('AuthService: signOut error $e');
    }
  }

  // Reauthenticate credential
  Future<void> reauthenticate(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(code: 'user-not-found', messageKey: 'user-not-found');
    }
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: reauth error ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    }
  }

  // Reauthenticate email
  Future<void> reauthenticateWithEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await reauthenticate(credential);
  }

  // Reauthenticate google
  Future<void> reauthenticateWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      await reauthenticate(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw const AuthFailure(
        code: 'google-sign-in-failed',
        messageKey: 'google-sign-in-failed',
      );
    }
  }

  // Delete user
  Future<void> deleteAuthUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: delete error ${e.code}');
      throw AuthFailure(code: e.code, messageKey: e.code);
    }
  }
}
