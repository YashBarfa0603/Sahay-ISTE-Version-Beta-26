import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/services/document_catalogue_service.dart';

void main() {
  group('Phase 1: Additional Document Custom Naming Tests', () {
    test('UserDocumentModel correctly serializes and deserializes custom displayName', () {
      final doc = UserDocumentModel(
        documentId: 'doc_123',
        userId: 'user_456',
        documentType: 'additional_document',
        documentName: 'Birth Certificate / जन्म प्रमाण पत्र',
        storagePath: 'vault/user_456/doc_123.pdf',
        fileType: 'pdf',
        fileSize: 204800,
        uploadedAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        publicId: 'vault/user_456/doc_123',
        downloadUrl: 'https://res.cloudinary.com/demo/image/upload/birth_cert.pdf',
      );

      final map = doc.toMap();
      expect(map['displayName'], 'Birth Certificate / जन्म प्रमाण पत्र');
      expect(map['documentName'], 'Birth Certificate / जन्म प्रमाण पत्र');
      expect(map['documentType'], 'additional_document');

      final reconstructed = UserDocumentModel.fromMap(map, 'doc_123');
      expect(reconstructed.displayName, 'Birth Certificate / जन्म प्रमाण पत्र');
      expect(reconstructed.resolvedDisplayName, 'Birth Certificate / जन्म प्रमाण पत्र');
      expect(reconstructed.documentType, 'additional_document');
    });

    test('resolvedDisplayName falls back to catalogue if displayName is absent', () {
      final doc = UserDocumentModel(
        documentId: 'doc_aadhaar',
        userId: 'user_456',
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar Card',
        storagePath: 'vault/user_456/aadhaar.pdf',
        fileType: 'pdf',
        fileSize: 102400,
        uploadedAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      expect(doc.resolvedDisplayName, 'Aadhaar Card');
    });

    test('DocumentCatalogueService registers and recognizes additional_document', () {
      final spec = DocumentCatalogueService.getDocumentByType('additional_document');
      expect(spec, isNotNull);
      expect(spec!.documentType, 'additional_document');
      expect(spec.displayName, 'Additional Document');
      expect(spec.displayNameHindi, 'अतिरिक्त दस्तावेज़');

      final matchedCanonical = DocumentCatalogueService.matchCanonicalId('Additional Document');
      expect(matchedCanonical, 'additional_document');

      final matchedHindi = DocumentCatalogueService.matchCanonicalId('अतिरिक्त दस्तावेज़');
      expect(matchedHindi, 'additional_document');
    });

    test('Custom name validation rejects empty, blank or whitespace strings', () {
      bool isValidCustomName(String? name) {
        if (name == null) return false;
        final trimmed = name.trim();
        return trimmed.isNotEmpty;
      }

      expect(isValidCustomName(''), isFalse);
      expect(isValidCustomName('   '), isFalse);
      expect(isValidCustomName('\n\t'), isFalse);
      expect(isValidCustomName(null), isFalse);
      expect(isValidCustomName('Birth Certificate'), isTrue);
      expect(isValidCustomName('  Medical Fitness Certificate  '), isTrue);
      expect(isValidCustomName('जन्म प्रमाण पत्र'), isTrue);
    });
  });
}
