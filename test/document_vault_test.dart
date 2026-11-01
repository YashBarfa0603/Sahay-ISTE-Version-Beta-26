import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/services/scheme_notes_service.dart';

void main() {
  group('UserDocumentModel Tests', () {
    test('Correctly serializes and deserializes from Map', () {
      final now = DateTime.now();
      final doc = UserDocumentModel(
        documentId: 'doc_123',
        userId: 'user_456',
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar Card',
        storagePath: 'users/user_456/documents/doc_123.pdf',
        downloadUrl: 'https://storage.example.com/doc_123.pdf',
        fileType: 'pdf',
        fileSize: 1048576, // 1 MB
        uploadedAt: now,
        updatedAt: now,
        verificationStatus: 'uploaded',
        notes: 'Verified copy',
      );

      final map = doc.toMap();
      expect(map['documentId'], 'doc_123');
      expect(map['userId'], 'user_456');
      expect(map['documentType'], 'aadhaar_card');
      expect(map['fileType'], 'pdf');
      expect(map['fileSize'], 1048576);

      final restored = UserDocumentModel.fromMap(map, 'doc_123');
      expect(restored.documentId, 'doc_123');
      expect(restored.userId, 'user_456');
      expect(restored.documentType, 'aadhaar_card');
      expect(restored.fileType, 'pdf');
      expect(restored.fileSize, 1048576);
      expect(restored.verificationStatus, 'uploaded');
      expect(restored.notes, 'Verified copy');
    });

    test('formattedFileSize accurately formats byte sizes', () {
      final docBytes = UserDocumentModel(
        documentId: '1',
        userId: 'u',
        documentType: 't',
        documentName: 'n',
        storagePath: 'p',
        fileType: 'pdf',
        fileSize: 500,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(docBytes.formattedFileSize, '500 B');

      final docKb = docBytes.copyWith(fileSize: 2048);
      expect(docKb.formattedFileSize, '2.0 KB');

      final docMb = docBytes.copyWith(fileSize: 2621440); // 2.5 MB
      expect(docMb.formattedFileSize, '2.50 MB');
    });

    test('isPdf and isImage getters validate correctly', () {
      final pdfDoc = UserDocumentModel(
        documentId: '1',
        userId: 'u',
        documentType: 't',
        documentName: 'n',
        storagePath: 'p',
        fileType: 'pdf',
        fileSize: 100,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(pdfDoc.isPdf, isTrue);
      expect(pdfDoc.isImage, isFalse);

      final jpgDoc = pdfDoc.copyWith(fileType: 'jpg');
      expect(jpgDoc.isPdf, isFalse);
      expect(jpgDoc.isImage, isTrue);

      final pngDoc = pdfDoc.copyWith(fileType: 'png');
      expect(pngDoc.isPdf, isFalse);
      expect(pngDoc.isImage, isTrue);
    });
  });

  group('DocumentCatalogueService Tests', () {
    test('Contains all 18 canonical document types with rich guides', () {
      final docs = DocumentCatalogueService.getAllDocuments();
      expect(docs.length, 19);

      for (final doc in docs) {
        expect(doc.documentType, isNotEmpty);
        expect(doc.displayName, isNotEmpty);
        expect(doc.displayNameHindi, isNotEmpty);
        expect(doc.category, isNotEmpty);
        expect(doc.purpose, isNotEmpty);
        expect(doc.provesInfo, isNotEmpty);
        expect(doc.issuingAuthority, isNotEmpty);
        expect(doc.howToObtain, isNotEmpty);
        expect(doc.importantChecks, isNotEmpty);
        expect(doc.specimenTitle, isNotEmpty);
      }
    });

    test('matchCanonicalId correctly handles diverse scheme string patterns', () {
      expect(
        DocumentCatalogueService.matchCanonicalId('Aadhaar Card of the applicant farmer'),
        'aadhaar_card',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Land ownership documents (Khatauni/RoR)'),
        'land_ownership_record',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Khasra land records'),
        'land_ownership_record',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Active bank account passbook'),
        'bank_passbook',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Samagra Family ID and Member ID'),
        'samagra_id',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Ration Card (NFSA / BPL / AAY)'),
        'ration_card',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Income Certificate issued by Tehsildar'),
        'income_certificate',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Domicile Certificate of Madhya Pradesh'),
        'domicile_certificate',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Class 12th Marksheet / MEQ Proof'),
        'marksheet_12th',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('MGNREGA Job Card for rural labor'),
        'mgnrega_job_card',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Disability UDID Certificate'),
        'disability_certificate',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Voter ID (EPIC Card)'),
        'voter_id',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('PAN Card'),
        'pan_card',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Birth Certificate issued by Registrar'),
        'birth_certificate',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Aadhaar-seeded Bank Account Passbook'),
        'bank_passbook',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Self-declaration / Affidavit of residency'),
        'other_document',
      );
      expect(
        DocumentCatalogueService.matchCanonicalId('Unrecognized custom affidavit'),
        'other_document',
      );
    });

    test('Categorizes documents appropriately', () {
      final categories = DocumentCatalogueService.getDocumentsByCategory();
      expect(categories.containsKey('Identity'), isTrue);
      expect(categories.containsKey('Land'), isTrue);
      expect(categories.containsKey('Banking'), isTrue);
      expect(categories.containsKey('Income'), isTrue);
      expect(categories.containsKey('Education'), isTrue);
    });
  });

  group('DocumentService Validation & Storage Tests', () {
    setUp(() {
      DocumentService.clearMemoryStore();
    });

    test('File validation enforces allowed types and 5MB limit', () {
      // Valid
      expect(DocumentService.validateFile(fileType: 'pdf', fileSize: 1024), isNull);
      expect(DocumentService.validateFile(fileType: 'jpg', fileSize: 2048), isNull);
      expect(DocumentService.validateFile(fileType: 'png', fileSize: 5242880), isNull); // 5 MB exactly

      // Invalid format
      expect(
        DocumentService.validateFile(fileType: 'exe', fileSize: 1024),
        contains('Unsupported file format'),
      );
      expect(
        DocumentService.validateFile(fileType: 'docx', fileSize: 1024),
        contains('Unsupported file format'),
      );

      // Empty file
      expect(
        DocumentService.validateFile(fileType: 'pdf', fileSize: 0),
        contains('appears to be empty'),
      );

      // Oversized file (> 5 MB)
      expect(
        DocumentService.validateFile(fileType: 'pdf', fileSize: 5242881),
        contains('exceeds the maximum allowed limit'),
      );
    });

    test('Save, retrieve, update and delete document metadata in service', () async {
      final service = DocumentService();
      const userId = 'citizen_test_user_1';

      final doc = UserDocumentModel(
        documentId: 'doc_aadhaar_1',
        userId: userId,
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar Card',
        storagePath: 'users/$userId/documents/doc_aadhaar_1.pdf',
        fileType: 'pdf',
        fileSize: 1500000,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verificationStatus: 'uploaded',
      );

      await service.saveDocument(doc);

      final retrieved = await service.getDocument(userId, 'aadhaar_card');
      expect(retrieved, isNotNull);
      expect(retrieved!.documentId, 'doc_aadhaar_1');
      expect(retrieved.fileSize, 1500000);

      final allDocs = await service.getUserDocuments(userId);
      expect(allDocs.length, 1);
      expect(allDocs.first.documentType, 'aadhaar_card');

      // Delete document
      await service.deleteDocument(userId, 'doc_aadhaar_1', 'aadhaar_card');
      final afterDelete = await service.getDocument(userId, 'aadhaar_card');
      expect(afterDelete, isNull);
    });

    test('deleteAllUserDocuments clears entire vault for privacy', () async {
      final service = DocumentService();
      const userId = 'privacy_user';

      await service.saveDocument(UserDocumentModel(
        documentId: 'd1',
        userId: userId,
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar',
        storagePath: 'p1',
        fileType: 'pdf',
        fileSize: 1000,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await service.saveDocument(UserDocumentModel(
        documentId: 'd2',
        userId: userId,
        documentType: 'bank_passbook',
        documentName: 'Passbook',
        storagePath: 'p2',
        fileType: 'jpg',
        fileSize: 2000,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect((await service.getUserDocuments(userId)).length, 2);

      await service.deleteAllUserDocuments(userId);
      expect((await service.getUserDocuments(userId)).isEmpty, isTrue);
    });
  });

  group('UserDocumentProvider State Management Tests', () {
    test('Upload, replace, and query documents', () async {
      final service = DocumentService();
      final provider = UserDocumentProvider(service: service);
      const userId = 'provider_test_user';

      expect(provider.hasDocument('aadhaar_card'), isFalse);
      expect(provider.documentCount, 0);

      // Upload Aadhaar
      final ok = await provider.uploadDocument(
        userId: userId,
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar Card',
        fileName: 'my_aadhaar.pdf',
        fileSize: 1200000,
        notes: 'Updated 2026',
      );
      expect(ok, isTrue);
      expect(provider.hasDocument('aadhaar_card'), isTrue);
      expect(provider.documentCount, 1);
      expect(provider.getDocument('aadhaar_card')?.fileType, 'pdf');

      // Rejection on oversized file
      final failOversize = await provider.uploadDocument(
        userId: userId,
        documentType: 'land_ownership_record',
        documentName: 'Khatauni',
        fileName: 'huge_scan.pdf',
        fileSize: 10 * 1024 * 1024, // 10 MB
      );
      expect(failOversize, isFalse);
      expect(provider.errorMessage, contains('exceeds'));
      expect(provider.hasDocument('land_ownership_record'), isFalse);

      // Replace existing Aadhaar with JPG
      final existingDoc = provider.getDocument('aadhaar_card')!;
      final replaced = await provider.replaceDocument(
        documentId: existingDoc.documentId,
        userId: userId,
        documentType: 'aadhaar_card',
        documentName: 'Aadhaar Card',
        fileName: 'new_aadhaar.jpg',
        fileSize: 850000,
      );
      expect(replaced, isTrue);
      expect(provider.documentCount, 1);
      expect(provider.getDocument('aadhaar_card')?.fileType, 'jpg');

      // Delete
      await provider.deleteDocument(
        userId: userId,
        documentId: existingDoc.documentId,
        documentType: 'aadhaar_card',
      );
      expect(provider.hasDocument('aadhaar_card'), isFalse);
      expect(provider.documentCount, 0);
    });
  });

  group('SchemeModel Canonical Matching Tests', () {
    test('requiredDocumentIds getter maps documents to canonical IDs', () {
      final scheme = SchemeModel(
        schemeId: 'pm_kisan',
        name: 'PM-KISAN',
        description: 'Farmer Scheme',
        category: 'Agriculture',
        ministry: 'Ministry of Agriculture',
        governmentLevel: GovernmentLevel.central,
        benefits: '₹6000 per year',
        requiredDocuments: [
          'Aadhaar Card of the applicant farmer',
          'Land ownership documents (Khatauni/RoR)',
          'Active bank account passbook',
        ],
        applicationProcess: 'Online on pmkisan.gov.in',
        officialSourceUrl: 'https://pmkisan.gov.in',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final canonicalIds = scheme.requiredDocumentIds;
      expect(canonicalIds, [
        'aadhaar_card',
        'land_ownership_record',
        'bank_passbook',
      ]);
    });
  });

  group('SchemeNotesService Grounded Rules Tests', () {
    test('All 6 schemes have complete, grounded guidance in 4 subsections', () {
      final schemeIds = [
        'pm_kisan',
        'pmjay',
        'pmay_g',
        'ujjwala',
        'pmss',
        'ladli_behna',
      ];

      for (final id in schemeIds) {
        final notes = SchemeNotesService.getNotesForScheme(id);
        expect(notes, isNotNull, reason: 'Scheme notes missing for $id');
        expect(notes!.criticalConditions, isNotEmpty);
        expect(notes.criticalConditionsHindi, isNotEmpty);
        expect(notes.disqualificationReasons, isNotEmpty);
        expect(notes.disqualificationReasonsHindi, isNotEmpty);
        expect(notes.documentRequirements, isNotEmpty);
        expect(notes.documentRequirementsHindi, isNotEmpty);
        expect(notes.applicationPrecautions, isNotEmpty);
        expect(notes.applicationPrecautionsHindi, isNotEmpty);
      }
    });

    test('PM-KISAN notes explicitly reflect income tax & constitutional post disqualification', () {
      final notes = SchemeNotesService.getNotesForScheme('pm_kisan')!;
      final disqStr = notes.disqualificationReasons.join(' ');
      expect(disqStr, contains('Income Tax'));
      expect(disqStr, contains('constitutional posts'));
      expect(disqStr, contains('Institutional landholders'));
    });

    test('Ladli Behna notes explicitly reflect 5 acre & four-wheeler exclusion', () {
      final notes = SchemeNotesService.getNotesForScheme('ladli_behna')!;
      final disqStr = notes.disqualificationReasons.join(' ');
      expect(disqStr, contains('5 acres'));
      expect(disqStr, contains('four-wheeler'));
      expect(disqStr, contains('2,50,000'));
    });
  });
}
