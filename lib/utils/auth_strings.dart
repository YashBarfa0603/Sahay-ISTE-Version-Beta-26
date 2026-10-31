// Auth strings
class AuthStrings {
  AuthStrings._();

  // Messages map by code
  static const Map<String, Map<String, String>> messages = {
    'invalid-credential': {
      'en': 'The email or password you entered is incorrect. Please check and try again.',
      'hi': 'आपके द्वारा दर्ज किया गया ईमेल या पासवर्ड गलत है। कृपया जांच कर पुनः प्रयास करें।',
    },
    'wrong-password': {
      'en': 'The email or password you entered is incorrect. Please check and try again.',
      'hi': 'आपके द्वारा दर्ज किया गया ईमेल या पासवर्ड गलत है। कृपया जांच कर पुनः प्रयास करें।',
    },
    'user-not-found': {
      'en': 'The email or password you entered is incorrect. Please check and try again.',
      'hi': 'आपके द्वारा दर्ज किया गया ईमेल या पासवर्ड गलत है। कृपया जांच कर पुनः प्रयास करें।',
    },
    'invalid-email': {
      'en': 'The email address format is not valid. Please enter a valid email.',
      'hi': 'ईमेल पता अमान्य है। कृपया एक मान्य ईमेल पता दर्ज करें।',
    },
    'email-already-in-use': {
      'en': 'An account already exists with this email address. Please sign in instead.',
      'hi': 'इस ईमेल पते के साथ पहले से ही एक खाता मौजूद है। कृपया साइन इन करें।',
    },
    'weak-password': {
      'en': 'The password is too weak. Please use at least 8 characters with letters and numbers.',
      'hi': 'पासवर्ड बहुत कमजोर है। कृपया अक्षरों और अंकों के साथ कम से कम 8 वर्णों का उपयोग करें।',
    },
    'network-request-failed': {
      'en': 'Network connection failed. Please check your internet connection and try again.',
      'hi': 'नेटवर्क कनेक्शन विफल रहा। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।',
    },
    'too-many-requests': {
      'en': 'Too many unsuccessful attempts. Access has been temporarily locked for security. Please try again later.',
      'hi': 'बहुत अधिक असफल प्रयास। सुरक्षा कारणों से एक्सेस को अस्थायी रूप से रोक दिया गया है। कृपया बाद में प्रयास करें।',
    },
    'user-disabled': {
      'en': 'This account has been disabled. Please contact support.',
      'hi': 'यह खाता अक्षम कर दिया गया है। कृपया सहायता से संपर्क करें।',
    },
    'operation-not-allowed': {
      'en': 'This sign-in method is currently not enabled.',
      'hi': 'यह साइन-इन विधि वर्तमान में सक्षम नहीं है।',
    },
    'account-exists-with-different-credential': {
      'en': 'An account already exists with this email using a different sign-in method. Please sign in using your original method.',
      'hi': 'इस ईमेल के साथ पहले से ही किसी अन्य साइन-इन विधि का उपयोग करके खाता मौजूद है। कृपया अपनी मूल विधि से साइन इन करें।',
    },
    'requires-recent-login': {
      'en': 'This security action requires recent authentication. Please sign out and sign in again before proceeding.',
      'hi': 'इस सुरक्षा कार्य के लिए हालिया प्रमाणीकरण आवश्यक है। कृपया आगे बढ़ने से पहले पुनः साइन इन करें।',
    },
    'google-sign-in-cancelled': {
      'en': 'Google sign-in was cancelled.',
      'hi': 'गूगल साइन-इन रद्द कर दिया गया।',
    },
    'reset-email-sent': {
      'en': 'If this email is registered, a password reset link has been sent to it.',
      'hi': 'यदि यह ईमेल पंजीकृत है, तो उस पर पासवर्ड रीसेट लिंक भेज दिया गया है।',
    },
    'unknown-error': {
      'en': 'An unexpected authentication error occurred. Please try again.',
      'hi': 'एक अप्रत्याशित प्रमाणीकरण त्रुटि हुई। कृपया पुनः प्रयास करें।',
    },
  };

  // Lookup
  static String getMessage(String code, [String lang = 'en']) {
    final cleanCode = code.trim().toLowerCase();
    final langKey = lang.toLowerCase() == 'hi' ? 'hi' : 'en';

    if (messages.containsKey(cleanCode)) {
      return messages[cleanCode]![langKey] ?? messages[cleanCode]!['en']!;
    }
    return messages['unknown-error']![langKey]!;
  }
}

