import 'dart:async';

/// Privacy and session data management service for SAHAY.
///
/// Implements a strict Zero-Retention Privacy Architecture:
/// - What we store: ONLY user language preference.
/// - What we NEVER store: user answers, income, caste, land details, Aadhaar, personal details.
/// - All eligibility computation and answers exist strictly in volatile memory (RAM)
///   for the duration of the active session and are instantly wiped when requested or on exit.
class PrivacyService {
  // Ephemeral in-memory session answers
  final Map<String, dynamic> _sessionAnswers = {};

  // Ephemeral assessment tracking
  final List<String> _assessedSchemeIds = [];

  // Allowed persistent setting: language preference only
  String _preferredLanguage = 'en';

  /// Clear all session data (user answers, results, evaluation history) from memory.
  Future<void> clearSessionData() async {
    _sessionAnswers.clear();
    _assessedSchemeIds.clear();
  }

  /// Check if any personal or assessment data currently exists in active memory.
  bool hasPersonalData() {
    return _sessionAnswers.isNotEmpty || _assessedSchemeIds.isNotEmpty;
  }

  /// Get the localization key for the full Privacy Policy text.
  String get privacyPolicyKey => 'privacy_policy_content';

  /// Retrieve the language preference (the only persistently retained setting).
  String get preferredLanguage => _preferredLanguage;

  /// Update the language preference.
  void setPreferredLanguage(String lang) {
    if (lang.trim().isNotEmpty) {
      _preferredLanguage = lang.trim();
    }
  }

  /// Ephemeral session answer getter (in-memory only).
  Map<String, dynamic> get sessionAnswers =>
      Map<String, dynamic>.unmodifiable(_sessionAnswers);

  /// Ephemeral answer retriever.
  dynamic getSessionAnswer(String field) {
    return _sessionAnswers[field];
  }

  /// Store an answer in volatile memory for the current session.
  void setSessionAnswer(String field, dynamic value) {
    if (value == null) {
      _sessionAnswers.remove(field);
    } else {
      _sessionAnswers[field] = value;
    }
  }

  /// Store multiple answers in volatile memory for the current session.
  void setSessionAnswers(Map<String, dynamic> answers) {
    _sessionAnswers.addAll(answers);
  }

  /// Remove a specific answer from volatile memory.
  void removeSessionAnswer(String field) {
    _sessionAnswers.remove(field);
  }

  /// Register an evaluated scheme ID in session memory.
  void recordAssessedScheme(String schemeId) {
    if (!_assessedSchemeIds.contains(schemeId)) {
      _assessedSchemeIds.add(schemeId);
    }
  }

  /// Get summary of privacy safeguards for display to the user.
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
