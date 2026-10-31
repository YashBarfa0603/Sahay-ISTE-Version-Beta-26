import 'package:flutter/foundation.dart';
import 'package:sahay/utils/auth_strings.dart';

// Failure representation
class AuthFailure implements Exception {
  final String code;
  final String messageKey;

  const AuthFailure({
    required this.code,
    this.messageKey = '',
  });

  String getLocalizedMessage([String lang = 'en']) {
    return AuthStrings.getMessage(code, lang);
  }

  @override
  String toString() => 'AuthFailure(code: $code)';
}

// Error mapper
class AuthErrorMapper {
  AuthErrorMapper._();

  // Extract code and map to message
  static String mapErrorToMessage(dynamic error, [String lang = 'en']) {
    final code = extractErrorCode(error);
    debugPrint('AuthErrorMapper: processing error code: $code');
    return AuthStrings.getMessage(code, lang);
  }

  // Extract clean code from exception
  static String extractErrorCode(dynamic error) {
    if (error == null) return 'unknown-error';

    if (error is AuthFailure) {
      return error.code;
    }

    try {
      // Duck typing for FirebaseAuthException.code
      final dynamic dyn = error;
      if (dyn.code != null && dyn.code is String) {
        final rawCode = (dyn.code as String).toLowerCase().trim();
        if (rawCode == 'email_exists' ||
            rawCode == 'email-already-exists' ||
            rawCode == 'user-already-exists') {
          return 'email-already-in-use';
        }
        if (rawCode == 'invalid_login_credentials') {
          return 'invalid-credential';
        }
        return rawCode;
      }
    } catch (_) {}

    final str = error.toString().toLowerCase();

    if (str.contains('invalid-credential') ||
        str.contains('wrong-password') ||
        str.contains('user-not-found') ||
        str.contains('invalid_login_credentials')) {
      return 'invalid-credential';
    }
    if (str.contains('invalid-email')) {
      return 'invalid-email';
    }
    if (str.contains('email-already-in-use') ||
        str.contains('email_exists') ||
        str.contains('email-already-exists') ||
        str.contains('user-already-exists')) {
      return 'email-already-in-use';
    }
    if (str.contains('weak-password')) {
      return 'weak-password';
    }
    if (str.contains('database') ||
        str.contains('permission-denied') ||
        str.contains('unavailable')) {
      return 'database-error';
    }
    if (str.contains('network') || str.contains('socket') || str.contains('connection')) {
      return 'network-request-failed';
    }
    if (str.contains('too-many-requests')) {
      return 'too-many-requests';
    }
    if (str.contains('requires-recent-login')) {
      return 'requires-recent-login';
    }

    return 'unknown-error';
  }
}

