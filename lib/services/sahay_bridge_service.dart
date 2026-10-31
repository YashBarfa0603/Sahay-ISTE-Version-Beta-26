import 'dart:convert';
import 'package:flutter/foundation.dart';

enum SahayBridgeAction {
  portalReady,
  populateResults,
  readbackResults,
  portalError,
  manualActionRequired,
  unknown,
}

class SahayBridgeMessage {
  final SahayBridgeAction action;
  final String rawAction;
  final String? sessionId;
  final List<Map<String, dynamic>> populateResults;
  final Map<String, dynamic> readBackData;
  final String? errorMessage;
  final String? manualActionType;
  final bool isValid;
  final String? validationError;

  SahayBridgeMessage({
    required this.action,
    required this.rawAction,
    this.sessionId,
    this.populateResults = const [],
    this.readBackData = const {},
    this.errorMessage,
    this.manualActionType,
    required this.isValid,
    this.validationError,
  });

  factory SahayBridgeMessage.parse({
    required String rawJson,
    required String expectedPortalDomain,
    required String currentUrl,
    String? currentSessionId,
    List<String>? validFieldIds,
  }) {
    // 1. Origin Security Validation: Ensure URL host matches expected portal domain
    final uri = Uri.tryParse(currentUrl);
    final host = uri?.host.toLowerCase() ?? '';
    final domain = expectedPortalDomain.toLowerCase().replaceAll('www.', '');

    if (!host.contains(domain) && !host.contains('localhost') && !host.contains('127.0.0.1')) {
      return SahayBridgeMessage(
        action: SahayBridgeAction.portalError,
        rawAction: 'UNTRUSTED_ORIGIN',
        isValid: false,
        validationError: 'Origin violation: $host does not match registered domain $expectedPortalDomain',
      );
    }

    // 2. JSON Decoding
    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      return SahayBridgeMessage(
        action: SahayBridgeAction.portalError,
        rawAction: 'JSON_PARSE_ERROR',
        isValid: false,
        validationError: 'Malformed bridge message: $e',
      );
    }

    if (decoded is! Map) {
      return SahayBridgeMessage(
        action: SahayBridgeAction.portalError,
        rawAction: 'INVALID_PAYLOAD',
        isValid: false,
        validationError: 'Bridge payload must be a JSON object',
      );
    }

    final rawAction = decoded['action']?.toString() ?? '';
    SahayBridgeAction action;

    switch (rawAction) {
      case 'PORTAL_READY':
        action = SahayBridgeAction.portalReady;
        break;
      case 'POPULATE_RESULTS':
        action = SahayBridgeAction.populateResults;
        break;
      case 'READBACK_RESULTS':
        action = SahayBridgeAction.readbackResults;
        break;
      case 'PORTAL_ERROR':
        action = SahayBridgeAction.portalError;
        break;
      case 'MANUAL_ACTION_REQUIRED':
        action = SahayBridgeAction.manualActionRequired;
        break;
      default:
        return SahayBridgeMessage(
          action: SahayBridgeAction.unknown,
          rawAction: rawAction,
          isValid: false,
          validationError: 'Unauthorized bridge action: $rawAction',
        );
    }

    // 3. Schema & Field Validation
    final List<Map<String, dynamic>> popResults = [];
    if (decoded['results'] is List) {
      for (final item in decoded['results'] as List) {
        if (item is Map) {
          final fId = item['field_id']?.toString() ?? '';
          if (validFieldIds != null && validFieldIds.isNotEmpty && !validFieldIds.contains(fId)) {
            debugPrint('SahayBridge: Warning - unrecognized field_id "$fId" in POPULATE_RESULTS');
          }
          popResults.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final Map<String, dynamic> readBack = {};
    if (decoded['data'] is Map) {
      final map = decoded['data'] as Map;
      for (final key in map.keys) {
        final kStr = key.toString();
        if (validFieldIds != null && validFieldIds.isNotEmpty && !validFieldIds.contains(kStr)) {
          debugPrint('SahayBridge: Warning - unrecognized field_id "$kStr" in READBACK_RESULTS');
        }
        readBack[kStr] = map[key];
      }
    }

    return SahayBridgeMessage(
      action: action,
      rawAction: rawAction,
      sessionId: currentSessionId,
      populateResults: popResults,
      readBackData: readBack,
      errorMessage: decoded['error']?.toString(),
      manualActionType: decoded['action_type']?.toString(),
      isValid: true,
    );
  }
}
