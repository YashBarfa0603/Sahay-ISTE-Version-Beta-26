import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/services/sahay_bridge_service.dart';

void main() {
  group('SahayBridge Secure JavaScript Channel Tests', () {
    const expectedDomain = 'pmkisan.gov.in';
    const validUrl = 'https://pmkisan.gov.in/RegistrationFormNew.aspx';
    const evilUrl = 'https://evil-phishing-site.com/steal-aadhaar';
    final validFields = ['aadhaar_number', 'farmer_name', 'mobile_number', 'state', 'district'];

    test('1. Validates trusted origin and accepts official portal URL', () {
      final msg = SahayBridgeMessage.parse(
        rawJson: '{"action": "PORTAL_READY"}',
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isTrue);
      expect(msg.action, SahayBridgeAction.portalReady);
      expect(msg.validationError, isNull);
    });

    test('2. Rejects untrusted / spoofed origin', () {
      final msg = SahayBridgeMessage.parse(
        rawJson: '{"action": "PORTAL_READY"}',
        expectedPortalDomain: expectedDomain,
        currentUrl: evilUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isFalse);
      expect(msg.action, SahayBridgeAction.portalError);
      expect(msg.validationError, contains('Origin violation'));
    });

    test('3. Parses valid POPULATE_RESULTS message with field records', () {
      final raw = '''
      {
        "action": "POPULATE_RESULTS",
        "results": [
          {"field_id": "aadhaar_number", "selector": "txt_Aadhar", "status": "success", "populated_value": "XXXXXXXX4321"},
          {"field_id": "mobile_number", "selector": "txt_Mobile", "status": "success", "populated_value": "9826012345"}
        ]
      }
      ''';

      final msg = SahayBridgeMessage.parse(
        rawJson: raw,
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isTrue);
      expect(msg.action, SahayBridgeAction.populateResults);
      expect(msg.populateResults.length, equals(2));
      expect(msg.populateResults[0]['field_id'], equals('aadhaar_number'));
      expect(msg.populateResults[0]['status'], equals('success'));
    });

    test('4. Parses valid READBACK_RESULTS message with inspected values', () {
      final raw = '''
      {
        "action": "READBACK_RESULTS",
        "data": {
          "aadhaar_number": "XXXXXXXX4321",
          "farmer_name": "Ramesh Chandra Patel",
          "state": "Madhya Pradesh"
        }
      }
      ''';

      final msg = SahayBridgeMessage.parse(
        rawJson: raw,
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isTrue);
      expect(msg.action, SahayBridgeAction.readbackResults);
      expect(msg.readBackData.length, equals(3));
      expect(msg.readBackData['farmer_name'], equals('Ramesh Chandra Patel'));
    });

    test('5. Rejects unauthorized / unexpected actions (prompt injection protection)', () {
      final raw = '{"action": "EXECUTE_ARBITRARY_SCRIPT", "code": "malicious();"}';

      final msg = SahayBridgeMessage.parse(
        rawJson: raw,
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isFalse);
      expect(msg.action, SahayBridgeAction.unknown);
      expect(msg.validationError, contains('Unauthorized bridge action'));
    });

    test('6. Rejects malformed JSON payloads gracefully', () {
      final msg = SahayBridgeMessage.parse(
        rawJson: '{not valid json: true}',
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isFalse);
      expect(msg.action, SahayBridgeAction.portalError);
      expect(msg.validationError, contains('Malformed bridge message'));
    });

    test('7. Handles PORTAL_ERROR and captures error diagnostics', () {
      final raw = '{"action": "PORTAL_ERROR", "error": "Gateway timeout connecting to UIDAI"}';

      final msg = SahayBridgeMessage.parse(
        rawJson: raw,
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isTrue);
      expect(msg.action, SahayBridgeAction.portalError);
      expect(msg.errorMessage, equals('Gateway timeout connecting to UIDAI'));
    });

    test('8. Handles MANUAL_ACTION_REQUIRED notification', () {
      final raw = '{"action": "MANUAL_ACTION_REQUIRED", "action_type": "CAPTCHA"}';

      final msg = SahayBridgeMessage.parse(
        rawJson: raw,
        expectedPortalDomain: expectedDomain,
        currentUrl: validUrl,
        validFieldIds: validFields,
      );

      expect(msg.isValid, isTrue);
      expect(msg.action, SahayBridgeAction.manualActionRequired);
      expect(msg.manualActionType, equals('CAPTCHA'));
    });
  });
}

