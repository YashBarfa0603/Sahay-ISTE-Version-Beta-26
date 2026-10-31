import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/services/api_client.dart';

class ApplicationApiService {
  final ApiClient _apiClient;

  ApplicationApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Starts a new application session on the backend.
  Future<ApplicationSession?> startApplication({
    required String schemeId,
    InteractionMode? mode,
    String language = 'en',
  }) async {
    try {
      final payload = {
        'scheme_id': schemeId,
        if (mode != null)
          'interaction_mode': mode == InteractionMode.directWeb ? 'direct_web' : 'guided_form',
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

  /// Retrieves an existing application session.
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

  /// Submits an answer for a guided form field.
  Future<ApplicationSession?> answerField({
    required String sessionId,
    required String fieldId,
    required dynamic value,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/guided-form/answer',
        data: {
          'field_id': fieldId,
          'value': value,
          'user_confirmed': true,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: answerField error: $e');
    }
    return null;
  }

  /// Confirms an explicit choice when profile and document disagree.
  Future<ApplicationSession?> confirmConflict({
    required String sessionId,
    required String fieldId,
    required dynamic confirmedValue,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/confirm-field',
        data: {
          'field_id': fieldId,
          'confirmed_value': confirmedValue,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return ApplicationSession.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ApplicationApiService: confirmConflict error: $e');
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
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/explain-field',
        data: {
          'field_id': fieldId,
          'field_label': fieldLabel,
          'language': language,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final d = Map<String, dynamic>.from(response.data as Map);
        return {
          'explanation': d['explanation']?.toString() ?? '',
          'example': d['example']?.toString() ?? '',
          'language': d['language']?.toString() ?? language,
        };
      }
    } catch (e) {
      debugPrint('ApplicationApiService: explainField error: $e');
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

  /// Fetches review synthesis payload.
  Future<Map<String, dynamic>?> getReviewSummary(String sessionId) async {
    try {
      final response = await _apiClient.get('/api/applications/$sessionId/review');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('ApplicationApiService: getReviewSummary error: $e');
    }
    return null;
  }

  /// Confirms application submission after explicit citizen approval.
  Future<bool> confirmSubmission({
    required String sessionId,
    required bool explicitApproval,
    String? acknowledgementNumber,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/applications/$sessionId/submission-confirmation',
        data: {
          'user_explicit_approval': explicitApproval,
          if (acknowledgementNumber != null) 'official_acknowledgement_number': acknowledgementNumber,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        return map['submitted'] == true;
      }
    } catch (e) {
      debugPrint('ApplicationApiService: confirmSubmission error: $e');
    }
    return false;
  }
}

