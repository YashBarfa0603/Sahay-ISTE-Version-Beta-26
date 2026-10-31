// Validators
class Validators {
  Validators._();

  // Full Name
  static String? validateFullName(String? value, [String lang = 'en']) {
    final trimmed = value?.trim() ?? '';
    final isHi = lang.toLowerCase() == 'hi';

    if (trimmed.isEmpty) {
      return isHi ? 'कृपया अपना पूरा नाम दर्ज करें' : 'Please enter your full name';
    }
    if (trimmed.length < 2) {
      return isHi
          ? 'नाम में कम से कम 2 अक्षर होने चाहिए'
          : 'Name must be at least 2 characters';
    }
    return null;
  }

  // Email
  static String? validateEmail(String? value, [String lang = 'en']) {
    final trimmed = value?.trim() ?? '';
    final isHi = lang.toLowerCase() == 'hi';

    if (trimmed.isEmpty) {
      return isHi ? 'कृपया अपना ईमेल पता दर्ज करें' : 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return isHi
          ? 'कृपया एक वैध ईमेल पता दर्ज करें'
          : 'Please enter a valid email address';
    }
    return null;
  }

  // Password
  static String? validatePassword(String? value, [String lang = 'en']) {
    final password = value ?? '';
    final isHi = lang.toLowerCase() == 'hi';

    if (password.isEmpty) {
      return isHi ? 'कृपया एक पासवर्ड दर्ज करें' : 'Please enter a password';
    }
    if (password.length < 8) {
      return isHi
          ? 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए'
          : 'Password must be at least 8 characters';
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    if (!hasLetter || !hasNumber) {
      return isHi
          ? 'पासवर्ड में कम से कम एक अक्षर और एक अंक होना चाहिए'
          : 'Password must contain at least one letter and one number';
    }
    return null;
  }

  // Confirm Password
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword, [
    String lang = 'en',
  ]) {
    final isHi = lang.toLowerCase() == 'hi';

    if (confirmPassword == null || confirmPassword.isEmpty) {
      return isHi ? 'कृपया पासवर्ड की पुष्टि करें' : 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return isHi ? 'पासवर्ड मेल नहीं खाते हैं' : 'Passwords do not match';
    }
    return null;
  }

  // Mobile
  static String? validateMobile(String? value, [String lang = 'en']) {
    final isHi = lang.toLowerCase() == 'hi';

    if (value == null || value.trim().isEmpty) {
      return isHi
          ? 'कृपया 10 अंकों का मोबाइल नंबर दर्ज करें'
          : 'Please enter a 10-digit mobile number';
    }

    final sanitized = sanitizeMobile(value);
    if (sanitized == null) {
      return isHi
          ? 'कृपया 6 से 9 से शुरू होने वाला 10 अंकों का वैध मोबाइल नंबर दर्ज करें'
          : 'Please enter a valid 10-digit mobile number starting with 6-9';
    }
    return null;
  }

  // Sanitize mobile: strips spaces, +91, 0 prefix, returns 10 digits
  static String? sanitizeMobile(String? value) {
    if (value == null) return null;
    String digits = value.replaceAll(RegExp(r'\s+'), '');

    if (digits.startsWith('+91')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    if (mobileRegex.hasMatch(digits)) {
      return digits;
    }
    return null;
  }

  // Age
  static String? validateAge(String? value, [String lang = 'en']) {
    final isHi = lang.toLowerCase() == 'hi';
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return isHi ? 'कृपया अपनी आयु दर्ज करें' : 'Please enter your age';
    }

    final age = int.tryParse(trimmed);
    if (age == null || age < 0 || age > 120) {
      return isHi
          ? 'कृपया 0 से 120 के बीच वैध आयु दर्ज करें'
          : 'Please enter a valid age between 0 and 120';
    }
    return null;
  }

  // Required Field
  static String? validateRequired(
    String? value,
    String fieldNameEnglish,
    String fieldNameHindi, [
    String lang = 'en',
  ]) {
    final isHi = lang.toLowerCase() == 'hi';
    if (value == null || value.trim().isEmpty) {
      return isHi
          ? 'कृपया $fieldNameHindi दर्ज करें'
          : 'Please provide $fieldNameEnglish';
    }
    return null;
  }
}

