import 'package:flutter/foundation.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/services/api_client.dart';

class ApplicationApiService {
  final ApiClient _apiClient;

  ApplicationApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches the 10 verified smart application filler schemes registry.
  Future<List<SchemeRegistryEntryModel>> getSupportedSchemes() async {
    try {
      final response = await _apiClient.get('/api/applications/supported-schemes');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => SchemeRegistryEntryModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('ApplicationApiService: getSupportedSchemes error: $e');
    }
    return [];
  }

  /// Starts or resumes a smart filler application session on the backend.
  Future<ApplicationSession?> startApplication({
    required String schemeId,
    Map<String, dynamic>? profileAnswers,
    String language = 'en',
    // Kept for backward compatibility
    InteractionMode? mode,
  }) async {
    try {
      final payload = {
        'scheme_id': schemeId,
        if (profileAnswers != null) 'user_profile_answers': profileAnswers,
        'language': language,
      };

      final response = await _apiClient.post(
        '/api/applications/start',
        data: payload,
      );

      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: startApplication error: $e');
    }
    return null;
  }

  /// Retrieves an existing application session by ID.
  Future<ApplicationSession?> getSession(String sessionId) async {
    try {
      final response = await _apiClient.get('/api/applications/$sessionId');
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: getSession error: $e');
    }
    return null;
  }

  /// Submits answers for multiple missing fields at once.
  Future<ApplicationSession?> answerMissingFields({
    required String sessionId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/answer-missing',
        data: {'answers': answers},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: answerMissingFields error: $e');
    }
    return null;
  }

  /// Backward-compatible single field answer.
  Future<ApplicationSession?> answerField({
    required String sessionId,
    required String fieldId,
    required dynamic value,
  }) async {
    return answerMissingFields(sessionId: sessionId, answers: {fieldId: value});
  }

  /// Resolves an explicit discrepancy where user profile and document OCR disagree.
  Future<ApplicationSession?> resolveConflict({
    required String sessionId,
    required String fieldId,
    required dynamic confirmedValue,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/resolve-conflict',
        data: {
          'field_id': fieldId,
          'confirmed_value': confirmedValue,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: resolveConflict error: $e');
    }
    return null;
  }

  /// Backward-compatible alias for resolveConflict.
  Future<ApplicationSession?> confirmConflict({
    required String sessionId,
    required String fieldId,
    required dynamic confirmedValue,
  }) async {
    return resolveConflict(sessionId: sessionId, fieldId: fieldId, confirmedValue: confirmedValue);
  }

  /// Fetches declarative population payload and read-back selectors for portal injection.
  Future<PortalPopulationPayloadModel?> getPortalPopulatePayload(String sessionId) async {
    try {
      final response = await _apiClient.get('/api/applications/$sessionId/portal/populate-payload');
      if (response.statusCode == 200 && response.data is Map) {
        return PortalPopulationPayloadModel.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: getPortalPopulatePayload error: $e');
    }
    return null;
  }

  /// Verifies read-back DOM state against expected session fields.
  Future<ReadBackVerificationReportModel?> verifyPortalReadback({
    required String sessionId,
    required Map<String, dynamic> readBackData,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/portal/verify-readback',
        data: {'read_back_data': readBackData},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ReadBackVerificationReportModel.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: verifyPortalReadback error: $e');
    }
    return null;
  }

  /// Validates the active application session.
  Future<Map<String, dynamic>?> validateSession(String sessionId) async {
    try {
      final response = await _apiClient.post('/api/applications/$sessionId/validate');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('ApplicationApiService: validateSession error: $e');
    }
    return null;
  }

  /// Final citizen submission confirmation.
  Future<ApplicationSession?> confirmSubmission({
    required String sessionId,
    required bool explicitApproval,
    String? acknowledgementNumber,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/confirm-submission',
        data: {
          'user_explicit_approval': explicitApproval,
          if (acknowledgementNumber != null) 'official_acknowledgement_number': acknowledgementNumber,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: confirmSubmission error: $e');
    }
    return null;
  }

  /// Fetches an AI explanation for a confusing field.
  Future<Map<String, String>?> explainField({
    required String sessionId,
    required String fieldId,
    required String fieldLabel,
    String language = 'en',
  }) async {
    // Default helpful fallback
    if (language == 'hi') {
      return {
        'explanation': 'कृपया अपने आधिकारिक दस्तावेजों के अनुसार $fieldLabel की सही जानकारी दर्ज करें।',
        'example': 'दस्तावेज़ में दर्ज सही जानकारी भरें।',
        'language': 'hi',
      };
    } else if (language.contains('hing')) {
      return {
        'explanation': '$fieldLabel ki sahi details official documents ke mutabiq yahan enter karein.',
        'example': 'Aadhaar ya certificates check karke bharein.',
        'language': 'hinglish',
      };
    }
    return {
      'explanation': 'Please enter accurate information for $fieldLabel matching your official government documents.',
      'example': 'Refer to your certificates before filling.',
      'language': 'en',
    };
  }
}
