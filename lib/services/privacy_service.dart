import 'dart:async';

class PrivacyService {
  // Session memory
  final Map<String, dynamic> _sessionAnswers = {};
  final List<String> _assessedSchemeIds = [];
  String _preferredLanguage = 'en';

  // Clear
  Future<void> clearSessionData() async {
    _sessionAnswers.clear();
    _assessedSchemeIds.clear();
  }

  // State check
  bool hasPersonalData() {
    return _sessionAnswers.isNotEmpty || _assessedSchemeIds.isNotEmpty;
  }

  String get privacyPolicyKey => 'privacy_policy_content';
  String get preferredLanguage => _preferredLanguage;

  void setPreferredLanguage(String lang) {
    if (lang.trim().isNotEmpty) {
      _preferredLanguage = lang.trim();
    }
  }

  // Session answers
  Map<String, dynamic> get sessionAnswers =>
      Map<String, dynamic>.unmodifiable(_sessionAnswers);

  dynamic getSessionAnswer(String field) {
    return _sessionAnswers[field];
  }

  void setSessionAnswer(String field, dynamic value) {
    if (value == null) {
      _sessionAnswers.remove(field);
    } else {
      _sessionAnswers[field] = value;
    }
  }

  void setSessionAnswers(Map<String, dynamic> answers) {
    _sessionAnswers.addAll(answers);
  }

  void removeSessionAnswer(String field) {
    _sessionAnswers.remove(field);
  }

  void recordAssessedScheme(String schemeId) {
    if (!_assessedSchemeIds.contains(schemeId)) {
      _assessedSchemeIds.add(schemeId);
    }
  }

  // Manifest
  Map<String, dynamic> getPrivacyManifest() {
    return const {
      'guarantee': 'Zero-Retention In-Memory Privacy Architecture',
      'persistedLocally': ['languagePreference'],
      'neverPersisted': [
        'userAnswers',
        'annualIncome',
        'casteCategory',
        'disabilityStatus',
        'landOwnership',
        'aadhaarDetails',
        'bankDetails',
        'eligibilityResults',
      ],
      'dataRetention':
          'All answers and computation data live only in temporary RAM during the active session. Nothing is written to permanent storage.',
      'thirdPartySharing': false,
      'isOfflineFirst': true,
    };
  }
}
