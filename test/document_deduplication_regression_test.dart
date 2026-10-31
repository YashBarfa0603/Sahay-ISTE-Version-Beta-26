import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/widgets/expandable_document_card.dart';

class MockDocumentService extends DocumentService {
  final Map<String, List<UserDocumentModel>> _store = {};

  @override
  Future<List<UserDocumentModel>> getUserDocuments(String userId) async {
    return _store[userId] ?? [];
  }

  void seedDocument(String userId, UserDocumentModel doc) {
    _store.putIfAbsent(userId, () => []).add(doc);
  }
}

SchemeModel _createSampleScheme({
  required String schemeId,
  required String name,
  required List<String> requiredDocuments,
}) {
  return SchemeModel(
    schemeId: schemeId,
    name: name,
    description: 'Test scheme description',
    category: 'welfare',
    ministry: 'Ministry of Social Welfare',
    governmentLevel: GovernmentLevel.central,
    benefits: 'Test benefits description',
    applicationProcess: 'Test application process',
    officialSourceUrl: 'https://example.gov.in',
    requiredDocuments: requiredDocuments,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SAHAY Document Deduplication & Requirement Filtering Regression Tests', () {
    // 1. Duplicate document IDs in scheme data
    test('1. Deduplicates raw canonical document IDs in scheme data', () {
      final scheme = _createSampleScheme(
        schemeId: 'test-1',
        name: 'Test Scheme 1',
        requiredDocuments: [
          'aadhaar_card',
          'aadhaar_card',
          'bank_passbook',
          'bank_passbook',
        ],
      );

      expect(scheme.requiredDocuments.length, 2);
      expect(scheme.requiredDocuments, contains('aadhaar_card'));
      expect(scheme.requiredDocuments, contains('bank_passbook'));
      expect(scheme.requiredDocumentIds, equals(['aadhaar_card', 'bank_passbook']));
    });

    // 2. Duplicate document names with different capitalization
    test('2. Deduplicates document names with varying case capitalization', () {
      final docs = [
        'Aadhaar Card',
        'aadhaar card',
        'AADHAAR CARD',
        'Income Certificate',
        'income certificate',
      ];
      final deduplicated = DocumentCatalogueService.deduplicateDocuments(docs);

      expect(deduplicated.length, 2);
      expect(deduplicated[0], equals('Aadhaar Card'));
      expect(deduplicated[1], equals('Income Certificate'));
    });

    // 3. Whitespace differences
    test('3. Deduplicates document names having extra leading, trailing, and internal whitespace', () {
      final docs = [
        '   Aadhaar    Card   ',
        'Aadhaar Card',
        '  Income   Certificate  ',
        'Income Certificate',
      ];
      final deduplicated = DocumentCatalogueService.deduplicateDocuments(docs);

      expect(deduplicated.length, 2);
      expect(deduplicated[0], equals('Aadhaar Card'));
      expect(deduplicated[1], equals('Income Certificate'));
    });

    // 4. Two genuinely different documents with similar names
    test('4. Preserves genuinely different documents and does not over-deduplicate', () {
      final docs = [
        'Aadhaar Card',
        'PAN Card',
        'Income Certificate',
        'Caste Certificate',
        'Domicile Certificate',
        'Birth Certificate',
        '10th Marksheet',
        '12th Marksheet',
        'Ex-Servicemen Certificate',
        'College Bonafide Admission Certificate',
      ];
      final deduplicated = DocumentCatalogueService.deduplicateDocuments(docs);

      expect(deduplicated.length, 10);
      expect(deduplicated, contains('Aadhaar Card'));
      expect(deduplicated, contains('PAN Card'));
      expect(deduplicated, contains('Income Certificate'));
      expect(deduplicated, contains('Caste Certificate'));
      expect(deduplicated, contains('Domicile Certificate'));
      expect(deduplicated, contains('Birth Certificate'));
      expect(deduplicated, contains('10th Marksheet'));
      expect(deduplicated, contains('12th Marksheet'));
      expect(deduplicated, contains('Ex-Servicemen Certificate'));
      expect(deduplicated, contains('College Bonafide Admission Certificate'));
    });

    // 5. Documents from different schemes
    test('5. Keeps requirements isolated per scheme without cross-scheme contamination', () {
      final schemeFarmer = _createSampleScheme(
        schemeId: 'scheme-farmer',
        name: 'Farmer Scheme',
        requiredDocuments: [
          'Aadhaar Card',
          'Land Ownership Record (Khatauni)',
          'Bank Account Passbook',
        ],
      );

      final schemeStudent = _createSampleScheme(
        schemeId: 'scheme-student',
        name: 'Student Scholarship Scheme',
        requiredDocuments: [
          'Aadhaar Card',
          '12th Marksheet',
          'College Bonafide Certificate',
        ],
      );

      expect(schemeFarmer.requiredDocuments.length, 3);
      expect(schemeFarmer.requiredDocuments, contains('Land Ownership Record (Khatauni)'));
      expect(schemeFarmer.requiredDocuments.contains('12th Marksheet'), isFalse);

      expect(schemeStudent.requiredDocuments.length, 3);
      expect(schemeStudent.requiredDocuments, contains('12th Marksheet'));
      expect(schemeStudent.requiredDocuments.contains('Land Ownership Record (Khatauni)'), isFalse);
    });

    // 6. Uploaded documents appearing only once
    testWidgets('6. Uploaded documents in vault appear exactly once in the scheme checklist', (tester) async {
      final mockService = MockDocumentService();
      final now = DateTime.now();

      // Seed user vault with multiple Aadhaar docs (e.g. multiple versions uploaded)
      mockService.seedDocument(
        'user_1',
        UserDocumentModel(
          documentId: 'doc_aadhaar_v1',
          userId: 'user_1',
          documentType: 'aadhaar_card',
          documentName: 'Aadhaar Card v1',
          storagePath: 'users/user_1/documents/aadhaar1.pdf',
          fileType: 'pdf',
          fileSize: 1024,
          uploadedAt: now,
          updatedAt: now,
        ),
      );

      final provider = UserDocumentProvider(service: mockService);
      await provider.loadDocuments('user_1');

      final scheme = _createSampleScheme(
        schemeId: 'scheme-aadhaar-test',
        name: 'Single Doc Scheme',
        requiredDocuments: [
          'Aadhaar Card',
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [SahayLocalizations.delegate],
            home: SchemeDetailScreen(scheme: scheme),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Exactly 1 ExpandableDocumentCard must be rendered
      expect(find.byType(ExpandableDocumentCard), findsOneWidget);
      expect(find.text('In Vault'), findsOneWidget);
    });

    // 7. Correct uploaded/missing status
    testWidgets('7. Displays correct uploaded and missing status for scheme requirements', (tester) async {
      final mockService = MockDocumentService();
      final now = DateTime.now();

      // Seed user vault with Aadhaar and Bank Passbook (and an unrelated Voter ID)
      mockService.seedDocument(
        'user_1',
        UserDocumentModel(
          documentId: 'doc_aadhaar',
          userId: 'user_1',
          documentType: 'aadhaar_card',
          documentName: 'Aadhaar Card',
          storagePath: 'users/user_1/documents/aadhaar.pdf',
          fileType: 'pdf',
          fileSize: 1024,
          uploadedAt: now,
          updatedAt: now,
        ),
      );
      mockService.seedDocument(
        'user_1',
        UserDocumentModel(
          documentId: 'doc_passbook',
          userId: 'user_1',
          documentType: 'bank_passbook',
          documentName: 'Bank Passbook',
          storagePath: 'users/user_1/documents/passbook.jpg',
          fileType: 'jpg',
          fileSize: 2048,
          uploadedAt: now,
          updatedAt: now,
        ),
      );
      mockService.seedDocument(
        'user_1',
        UserDocumentModel(
          documentId: 'doc_voter',
          userId: 'user_1',
          documentType: 'voter_id',
          documentName: 'Voter ID',
          storagePath: 'users/user_1/documents/voter.png',
          fileType: 'png',
          fileSize: 4096,
          uploadedAt: now,
          updatedAt: now,
        ),
      );

      final provider = UserDocumentProvider(service: mockService);
      await provider.loadDocuments('user_1');

      // Scheme requires: Aadhaar Card, Income Certificate, Bank Passbook
      final scheme = _createSampleScheme(
        schemeId: 'scheme-test',
        name: 'Test Welfare Scheme',
        requiredDocuments: [
          'Aadhaar Card',
          'Income Certificate',
          'Bank Passbook',
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [SahayLocalizations.delegate],
            home: SchemeDetailScreen(scheme: scheme),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Documents tab (index 1)
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Exactly 3 ExpandableDocumentCards must be rendered
      final cardFinder = find.byType(ExpandableDocumentCard);
      expect(cardFinder, findsNWidgets(3));

      // Voter ID is in vault, but NOT required by this scheme, so it must NOT appear
      expect(find.text('Voter ID'), findsNothing);

      // Verify Uploaded vs Not Uploaded badges:
      // Aadhaar -> In Vault (Uploaded)
      // Bank Passbook -> In Vault (Uploaded)
      // Income Certificate -> Not in Vault (Missing)
      expect(find.text('In Vault'), findsNWidgets(2));
      expect(find.text('Not in Vault'), findsNWidgets(1));

      // Vault summary count banner
      expect(find.text('Personal Vault Match: 2/3 documents in vault'), findsOneWidget);
    });

    // 8. Switching between schemes without carrying over previous checklist
    testWidgets('8. Switching between schemes clears the previous checklist selection', (tester) async {
      final schemeA = _createSampleScheme(
        schemeId: 'scheme-a',
        name: 'Scheme Alpha',
        requiredDocuments: ['Aadhaar Card', 'Ration Card'],
      );

      final schemeB = _createSampleScheme(
        schemeId: 'scheme-b',
        name: 'Scheme Beta',
        requiredDocuments: ['10th Marksheet', '12th Marksheet'],
      );

      final provider = UserDocumentProvider(service: MockDocumentService());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [SahayLocalizations.delegate],
            home: SchemeDetailScreen(scheme: schemeA),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Initially 0/2 Ready
      expect(find.text('0/2 Ready'), findsOneWidget);

      // Check first document in Scheme A
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      // Now 1/2 Ready
      expect(find.text('1/2 Ready'), findsOneWidget);

      // Switch to Scheme B by pushing new route
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [SahayLocalizations.delegate],
            home: SchemeDetailScreen(scheme: schemeB),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // In Scheme B, checklist must start fresh at 0/2 Ready, not carry over 1/2 from Scheme A
      expect(find.text('0/2 Ready'), findsOneWidget);
    });

    // 9. Empty required-document lists
    testWidgets('9. Safely renders schemes with empty required documents list', (tester) async {
      final emptyScheme = _createSampleScheme(
        schemeId: 'scheme-empty',
        name: 'Open Access Scheme',
        requiredDocuments: [],
      );

      final provider = UserDocumentProvider(service: MockDocumentService());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [SahayLocalizations.delegate],
            home: SchemeDetailScreen(scheme: emptyScheme),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('0/0 Ready'), findsOneWidget);
      expect(find.text('Personal Vault Match: 0/0 documents in vault'), findsOneWidget);
      expect(find.text('No specialized documents mandated beyond standard Aadhaar KYC.'), findsOneWidget);
      expect(find.byType(ExpandableDocumentCard), findsNothing);
    });

    // 10. Duplicate API response entries
    test('10. SchemeModel.fromMap cleanly deduplicates entries from API responses', () {
      final apiResponse = {
        'schemeId': 'api-scheme-001',
        'name': 'API Welfare Scheme',
        'description': 'Description from REST API',
        'category': 'agriculture',
        'ministry': 'Ministry of Agriculture',
        'governmentLevel': 'central',
        'benefits': 'Subsidy benefits',
        'applicationProcess': 'Online portal',
        'officialSourceUrl': 'https://agri.gov.in',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'requiredDocuments': [
          'Aadhaar Card',
          'aadhaar card',
          '   Aadhaar   Card  ',
          'Bank Passbook',
          'Bank Passbook',
          'Proof of Land Ownership',
          'Proof of Land Ownership',
        ],
      };

      final scheme = SchemeModel.fromMap(apiResponse);

      expect(scheme.requiredDocuments.length, 3);
      expect(scheme.requiredDocuments, contains('Aadhaar Card'));
      expect(scheme.requiredDocuments, contains('Bank Passbook'));
      expect(scheme.requiredDocuments, contains('Proof of Land Ownership'));
      expect(scheme.requiredDocumentIds, equals(['aadhaar_card', 'bank_passbook', 'land_ownership_record']));
    });
  });
}
