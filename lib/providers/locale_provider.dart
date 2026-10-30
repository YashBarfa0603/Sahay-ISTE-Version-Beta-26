import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localePrefsKey = 'selected_language_code';

  static const List<String> _supportedCodes = [
    'en',
    'hi',
    'ta',
    'mr',
    'bn',
    'gu',
    'kn',
    'or',
  ];

  static const Map<String, String> _nativeLanguageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'mr': 'मराठी',
    'bn': 'বাংলা',
    'gu': 'ગુજરાતી',
    'kn': 'ಕನ್ನಡ',
    'or': 'ଓଡ଼ିଆ',
  };

  static const Map<String, String> _englishLanguageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'mr': 'Marathi',
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'or': 'Odia',
  };

  // Assets
  static const Map<String, String> _characterAssets = {
    'en': 'assets/English.jpeg',
    'hi': 'assets/Hindi.jpeg',
    'ta': 'assets/Tamil.jpeg',
    'mr': 'assets/Marathi.jpeg',
    'bn': 'assets/Bangali.jpeg',
    'gu': 'assets/Gujarati.jpeg',
    'kn': 'assets/Kannada.jpeg',
    'or': 'assets/Odia.jpeg',
  };

  Locale _locale = const Locale('en');

  LocaleProvider() {
    loadSavedLocale();
  }

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isIndicScript => _locale.languageCode != 'en';

  // Set locale
  Future<void> setLocale(Locale newLocale) async {
    final code = newLocale.languageCode.toLowerCase();
    if (!_supportedCodes.contains(code)) return;
    if (_locale.languageCode == code) return;

    _locale = Locale(code);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefsKey, code);
    } catch (e) {
      debugPrint('LocaleProvider error: $e');
    }
  }

  // Load locale
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_localePrefsKey);
      if (savedCode != null && _supportedCodes.contains(savedCode.toLowerCase())) {
        if (_locale.languageCode != savedCode) {
          _locale = Locale(savedCode.toLowerCase());
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('LocaleProvider error: $e');
    }
  }

  // Asset helper
  String getCharacterAsset(String langCode) {
    return _characterAssets[langCode.toLowerCase()] ?? 'assets/English.jpeg';
  }

  String get currentCharacterAsset => getCharacterAsset(_locale.languageCode);

  // Names
  String getNativeLanguageName(String langCode) {
    return _nativeLanguageNames[langCode.toLowerCase()] ?? 'English';
  }

  String getEnglishLanguageName(String langCode) {
    return _englishLanguageNames[langCode.toLowerCase()] ?? 'English';
  }

  // Supported languages
  List<Map<String, String>> get supportedLanguages {
    return _supportedCodes.map((code) {
      return {
        'code': code,
        'name': _englishLanguageNames[code] ?? code,
        'nativeName': _nativeLanguageNames[code] ?? code,
        'asset': _characterAssets[code] ?? 'assets/English.jpeg',
      };
    }).toList();
  }
}
