// Validators
class Validators {
  Validators._();

  static const Map<String, Map<String, String>> _messages = {
    'enterFullName': {
      'en': 'Please enter your full name',
      'hi': 'कृपया अपना पूरा नाम दर्ज करें',
      'ta': 'தயவுசெய்து உங்கள் முழுப் பெயரை உள்ளிடவும்',
      'mr': 'कृपया आपले पूर्ण नाव प्रविष्ट करा',
      'bn': 'দয়া করে আপনার সম্পূর্ণ নাম লিখুন',
      'gu': 'કૃપા કરીને તમારું પૂરું નામ દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಪೂರ್ಣ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ଆପଣଙ୍କ ପୂରା ନାମ ଦିଅନ୍ତୁ',
    },
    'nameMinLength': {
      'en': 'Name must be at least 2 characters',
      'hi': 'नाम में कम से कम 2 अक्षर होने चाहिए',
      'ta': 'பெயர் குறைந்தபட்சம் 2 எழுத்துக்கள் இருக்க வேண்டும்',
      'mr': 'नावात किमान २ अक्षरे असणे आवश्यक आहे',
      'bn': 'নাম কমপক্ষে ২ অক্ষরের হতে হবে',
      'gu': 'નામ ઓછામાં ઓછું 2 અક્ષરનું હોવું જોઈએ',
      'kn': 'ಹೆಸರು ಕನಿಷ್ಠ 2 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು',
      'or': 'ନାମ ଅତି କମରେ ୨ ଅକ୍ଷରର ହେବା ଉଚିତ',
    },
    'enterEmail': {
      'en': 'Please enter your email address',
      'hi': 'कृपया अपना ईमेल पता दर्ज करें',
      'ta': 'தயவுசெய்து உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்',
      'mr': 'कृपया आपला ईमेल पत्ता प्रविष्ट करा',
      'bn': 'দয়া করে আপনার ইমেল ঠিকানা লিখুন',
      'gu': 'કૃપા કરીને તમારું ઇમેઇલ સરનામું દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ଆପଣଙ୍କ ଇମେଲ ଠିକଣା ଦିଅନ୍ତୁ',
    },
    'invalidEmail': {
      'en': 'Please enter a valid email address',
      'hi': 'कृपया एक वैध ईमेल पता दर्ज करें',
      'ta': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்',
      'mr': 'कृपया वैध ईमेल पत्ता प्रविष्ट करा',
      'bn': 'দয়া করে একটি সঠিক ইমেল ঠিকানা লিখুন',
      'gu': 'કૃપા કરીને માન્ય ઇમેઇલ સરનામું દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ଏକ ବୈଧ ଇମେଲ ଠିକଣା ଦିଅନ୍ତୁ',
    },
    'enterPassword': {
      'en': 'Please enter a password',
      'hi': 'कृपया एक पासवर्ड दर्ज करें',
      'ta': 'கடவுச்சொல்லை உள்ளிடவும்',
      'mr': 'कृपया पासवर्ड प्रविष्ट करा',
      'bn': 'দয়া করে একটি পাসওয়ার্ড লিখুন',
      'gu': 'કૃપા કરીને પાસવર્ડ દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು ಗುಪ್ತಪದವನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ଏକ ପାସୱାର୍ଡ ଦିଅନ୍ତୁ',
    },
    'passwordMinLength': {
      'en': 'Password must be at least 8 characters',
      'hi': 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए',
      'ta': 'கடவுச்சொல் குறைந்தபட்சம் 8 எழுத்துக்கள் இருக்க வேண்டும்',
      'mr': 'पासवर्ड किमान ८ अक्षरांचा असावा',
      'bn': 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে',
      'gu': 'પાસવર્ડ ઓછામાં ઓછો 8 અક્ષરોનો હોવો જોઈએ',
      'kn': 'ಗುಪ್ತಪದ ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳಾಗಿರಬೇಕು',
      'or': 'ପାସୱାର୍ଡ ଅତି କମରେ ୮ ଅକ୍ଷରର ହେବା ଆବଶ୍ୟକ',
    },
    'passwordRequirements': {
      'en': 'Password must contain at least one letter and one number',
      'hi': 'पासवर्ड में कम से कम एक अक्षर और एक अंक होना चाहिए',
      'ta': 'கடவுச்சொல்லில் குறைந்தபட்சம் ஒரு எழுத்தும் ஒரு எண்ணும் இருக்க வேண்டும்',
      'mr': 'पासवर्डमध्ये किमान एक अक्षर आणि एक अंक असावा',
      'bn': 'পাসওয়ার্ডে অন্তত একটি অক্ষর এবং একটি সংখ্যা থাকতে হবে',
      'gu': 'પાસવર્ડમાં ઓછામાં ઓછો એક અક્ષર અને એક નંબર હોવો જોઈએ',
      'kn': 'ಗುಪ್ತಪದವು ಕನಿಷ್ಠ ಒಂದು ಅಕ್ಷರ ಮತ್ತು ಒಂದು ಸಂಖ್ಯೆಯನ್ನು ಹೊಂದಿರಬೇಕು',
      'or': 'ପାସୱାର୍ଡରେ ଅତି କମରେ ଗୋଟିଏ ଅକ୍ଷର ଏବଂ ଗୋଟିଏ ସଂଖ୍ୟା ରହିବା ଉଚିତ',
    },
    'confirmPassword': {
      'en': 'Please confirm your password',
      'hi': 'कृपया पासवर्ड की पुष्टि करें',
      'ta': 'தயவுசெய்து கடவுச்சொல்லை உறுதிப்படுத்தவும்',
      'mr': 'कृपया पासवर्डची पुष्टी करा',
      'bn': 'দয়া করে পাসওয়ার্ড নিশ্চিত করুন',
      'gu': 'કૃપા કરીને પાસવર્ડની પુષ્ટિ કરો',
      'kn': 'ದಯವಿಟ್ಟು ಗುಪ್ತಪದವನ್ನು ದೃಢೀಕರಿಸಿ',
      'or': 'ଦୟାକରି ପାସୱାର୍ଡ ନିଶ୍ଚିତ କରନ୍ତୁ',
    },
    'passwordsMismatch': {
      'en': 'Passwords do not match',
      'hi': 'पासवर्ड मेल नहीं खाते हैं',
      'ta': 'கடவுச்சொற்கள் பொருந்தவில்லை',
      'mr': 'पासवर्ड जुळत नाहीत',
      'bn': 'পাসওয়ার্ড মিলছে না',
      'gu': 'પાસવર્ડ મેળ ખાતા નથી',
      'kn': 'ಗುಪ್ತಪದಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
      'or': 'ପାସୱାର୍ଡ ମେଳ ଖାଉନାହିଁ',
    },
    'enterMobile': {
      'en': 'Please enter a 10-digit mobile number',
      'hi': 'कृपया 10 अंकों का मोबाइल नंबर दर्ज करें',
      'ta': '10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
      'mr': 'कृपया १० अंकी मोबाईल नंबर प्रविष्ट करा',
      'bn': 'দয়া করে ১০ সংখ্যার মোবাইল নম্বর লিখুন',
      'gu': 'કૃપા કરીને 10 અંકનો મોબાઇલ નંબર દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು 10 ಅಂಕಿಗಳ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ୧୦ ଅଙ୍କ ବିଶିଷ୍ଟ ମୋବାଇଲ ନମ୍ବର ଦିଅନ୍ତୁ',
    },
    'invalidMobile': {
      'en': 'Please enter a valid 10-digit mobile number starting with 6-9',
      'hi': 'कृपया 6 से 9 से शुरू होने वाला 10 अंकों का वैध मोबाइल नंबर दर्ज करें',
      'ta': '6-9 இல் தொடங்கும் சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
      'mr': 'कृपया ६ ते ९ ने सुरू होणारा वैध १० अंकी मोबाईल नंबर प्रविष्ट करा',
      'bn': 'দয়া করে ৬-৯ দিয়ে শুরু হওয়া ১০ সংখ্যার সঠিক মোবাইল নম্বর লিখুন',
      'gu': 'કૃપા કરીને 6-9 થી શરૂ થતો માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು 6-9 ರಿಂದ ಪ್ರಾರಂಭವಾಗುವ ಮಾನ್ಯವಾದ 10 ಅಂಕಿಗಳ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ୬-୯ ରୁ ଆରମ୍ଭ ହେଉଥିବା ୧୦ ଅଙ୍କ ବିଶିଷ୍ଟ ବୈଧ ମୋବାଇଲ ନମ୍ବର ଦିଅନ୍ତୁ',
    },
    'enterAge': {
      'en': 'Please enter your age',
      'hi': 'कृपया अपनी आयु दर्ज करें',
      'ta': 'தயவுசெய்து உங்கள் வயதை உள்ளிடவும்',
      'mr': 'कृपया आपले वय प्रविष्ट करा',
      'bn': 'দয়া করে আপনার বয়স লিখুন',
      'gu': 'કૃપા કરીને તમારી ઉંમર દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ವಯಸ್ಸನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ଆପଣଙ୍କ ବୟସ ଦିଅନ୍ତୁ',
    },
    'invalidAge': {
      'en': 'Please enter a valid age between 0 and 120',
      'hi': 'कृपया 0 से 120 के बीच वैध आयु दर्ज करें',
      'ta': '0 முதல் 120 வரை சரியான வயதை உள்ளிடவும்',
      'mr': 'कृपया ० ते १२० दरम्यान वैध वय प्रविष्ट करा',
      'bn': 'দয়া করে ০ থেকে ১২০ এর মধ্যে একটি বৈধ বয়স লিখুন',
      'gu': 'કૃપા કરીને 0 થી 120 વચ્ચેની માન્ય ઉંમર દાખલ કરો',
      'kn': 'ದಯವಿಟ್ಟು 0 ಮತ್ತು 120 ರ ನಡುವಿನ ಮಾನ್ಯ ವಯಸ್ಸನ್ನು ನಮೂದಿಸಿ',
      'or': 'ଦୟାକରି ୦ ରୁ ୧୨୦ ମଧ୍ୟରେ ଏକ ବୈଧ ବୟସ ଦିଅନ୍ତୁ',
    },
  };

  static String _msg(String key, String lang) {
    final l = lang.toLowerCase();
    return _messages[key]?[l] ?? _messages[key]?['en'] ?? '';
  }

  // Full Name
  static String? validateFullName(String? value, [String lang = 'en']) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _msg('enterFullName', lang);
    }
    if (trimmed.length < 2) {
      return _msg('nameMinLength', lang);
    }
    return null;
  }

  // Email
  static String? validateEmail(String? value, [String lang = 'en']) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _msg('enterEmail', lang);
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return _msg('invalidEmail', lang);
    }
    return null;
  }

  // Password
  static String? validatePassword(String? value, [String lang = 'en']) {
    final password = value ?? '';
    if (password.isEmpty) {
      return _msg('enterPassword', lang);
    }
    if (password.length < 8) {
      return _msg('passwordMinLength', lang);
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    if (!hasLetter || !hasNumber) {
      return _msg('passwordRequirements', lang);
    }
    return null;
  }

  // Confirm Password
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword, [
    String lang = 'en',
  ]) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return _msg('confirmPassword', lang);
    }
    if (password != confirmPassword) {
      return _msg('passwordsMismatch', lang);
    }
    return null;
  }

  // Mobile
  static String? validateMobile(String? value, [String lang = 'en']) {
    if (value == null || value.trim().isEmpty) {
      return _msg('enterMobile', lang);
    }

    final sanitized = sanitizeMobile(value);
    if (sanitized == null) {
      return _msg('invalidMobile', lang);
    }
    return null;
  }

  static String? validateMobileNumber(String? value, [String lang = 'en']) =>
      validateMobile(value, lang);

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
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _msg('enterAge', lang);
    }

    final age = int.tryParse(trimmed);
    if (age == null || age < 0 || age > 120) {
      return _msg('invalidAge', lang);
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
