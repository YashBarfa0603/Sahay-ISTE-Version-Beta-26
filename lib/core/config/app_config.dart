class AppConfig {
  AppConfig._();

  // App
  static const String appName = 'SAHAY';
  static const String appNameHindi = 'सहाय';
  static const String appTagline = 'Empowering Citizens, Enabling Benefits';
  static const String appTaglineHindi = 'नागरिकों का सशक्तिकरण, योजनाओं का लाभ';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // API
  static const String apiBaseUrl = 'https://api.sahay.gov.in/v1';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Session
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration inactivityTimeout = Duration(minutes: 15);
  static const bool defaultSessionOnly = true;
  static const bool autoClearSessionOnExit = true;
  static const int defaultDataRetentionDays = 0;
  static const bool allowAnonymousAssessment = true;
  static const bool allowOfflineStorage = true;
  static const bool allowAnalytics = false;

  // Features
  static const bool enableVoiceInput = true;
  static const bool enableOfflineEligibility = true;
  static const bool enableDocumentChecklistExport = true;
  static const bool enableShareEligibility = true;

  // Links
  static const String officialNationalPortalUrl = 'https://www.myscheme.gov.in';
  static const String supportEmail = 'support@sahay.gov.in';
  static const String nationalHelplineNumber = '1800-111-999';
  static const String privacyPolicyUrl = 'https://sahay.gov.in/privacy';
  static const String termsOfServiceUrl = 'https://sahay.gov.in/terms';

  // Languages
  static const String defaultLanguageCode = 'en';
  static const List<String> supportedLanguageCodes = [
    'en',
    'hi',
    'ta',
    'mr',
    'bn',
    'gu',
    'kn',
    'or',
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'mr': 'मराठी (Marathi)',
    'bn': 'বাংলা (Bengali)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'or': 'ଓଡ଼ିଆ (Odia)',
  };

  static const Map<String, String> languageNativeNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'mr': 'मराठी',
    'bn': 'বাংলা',
    'gu': 'ગુજરાતી',
    'kn': 'ಕನ್ನಡ',
    'or': 'ଓଡ଼ିଆ',
  };

  // Assets
  static const Map<String, String> characterAssets = {
    'en': 'assets/English.jpeg',
    'hi': 'assets/Hindi.jpeg',
    'ta': 'assets/Tamil.jpeg',
    'mr': 'assets/Marathi.jpeg',
    'bn': 'assets/Bangali.jpeg',
    'gu': 'assets/Gujarati.jpeg',
    'kn': 'assets/Kannada.jpeg',
    'or': 'assets/Odia.jpeg',
  };

  static String getCharacterAsset(String languageCode) {
    return characterAssets[languageCode] ?? 'assets/English.jpeg';
  }
}
