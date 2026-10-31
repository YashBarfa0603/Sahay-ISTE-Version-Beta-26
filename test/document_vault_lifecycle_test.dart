import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_theme.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/my_documents_screen.dart';
import 'package:sahay/services/document_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 — Document Vault Functional Lifecycle Tests', () {
    setUp(() {
      DocumentService.clearMemoryStore();
    });

    test('uploadDocumentFile enforces private path users/{userId}/documents/{documentType}/{fileName}',
        () async {
      final service = DocumentService();
      const userId = 'citizen_999';
      const docType = 'aadhaar_card';
      const fileName = 'aadhaar scan 2026.pdf';
      final fileBytes = Uint8List.fromList(List.filled(2048, 1)); // 2 KB

      double progressNotified = 0.0;
      final result = await service.uploadDocumentFile(
        userId: userId,
        documentType: docType,
        fileName: fileName,
        fileBytes: fileBytes,
        onProgress: (p) => progressNotified = p,
      );

      // Verify sanitized path matches requirement
      expect(result.storagePath, 'users/citizen_999/documents/aadhaar_card/aadhaar_scan_2026.pdf');
      expect(result.fileSize, 2048);
      expect(result.fileType, 'pdf');
      expect(progressNotified, greaterThan(0.0));

      // Verify cached bytes retrieval
      final bytesRetrieved = await service.getDocumentBytes(result.storagePath);
      expect(bytesRetrieved, isNotNull);
      expect(bytesRetrieved!.length, 2048);
    });

    test('uploadDocumentFile rejects invalid file formats with readable error', () async {
      final service = DocumentService();
      const userId = 'citizen_999';
      final fileBytes = Uint8List.fromList(List.filled(100, 1));

      expect(
        () => service.uploadDocumentFile(
          userId: userId,
          documentType: 'pan_card',
          fileName: 'trojan.exe',
          fileBytes: fileBytes,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Unsupported file format'),
        )),
      );
    });

    test('uploadDocumentFile rejects oversized files (> 5MB)', () async {
      final service = DocumentService();
      const userId = 'citizen_999';
      // 5 MB + 1 byte
      final oversizedBytes = Uint8List.fromList(List.filled(5 * 1024 * 1024 + 1, 1));

      expect(
        () => service.uploadDocumentFile(
          userId: userId,
          documentType: 'caste_certificate',
          fileName: 'caste.pdf',
          fileBytes: oversizedBytes,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('exceeds the maximum allowed limit of 5.0 MB'),
        )),
      );
    });

    test('replaceDocument uploads new file, updates Firestore, and purges old storage file',
        () async {
      final service = DocumentService();
      final provider = UserDocumentProvider(service: service);
      const userId = 'citizen_replace_test';

      final fileBytesV1 = Uint8List.fromList(List.filled(1024, 1));
      final fileBytesV2 = Uint8List.fromList(List.filled(2048, 2));

      // 1. Initial Upload
      final ok = await provider.uploadDocument(
        userId: userId,
        documentType: 'income_certificate',
        documentName: 'Income Certificate',
        fileName: 'income_v1.pdf',
        fileSize: 1024,
        fileBytes: fileBytesV1,
      );
      expect(ok, isTrue);

      final initialDoc = provider.getDocument('income_certificate')!;
      final oldPath = initialDoc.storagePath;
      expect(await service.getDocumentBytes(oldPath), isNotNull);

      // 2. Replace with newer version (JPG)
      final replaced = await provider.replaceDocument(
        documentId: initialDoc.documentId,
        userId: userId,
        documentType: 'income_certificate',
        documentName: 'Income Certificate',
        fileName: 'income_v2.jpg',
        fileSize: 2048,
        fileBytes: fileBytesV2,
        oldStoragePath: oldPath,
      );
      expect(replaced, isTrue);

      final updatedDoc = provider.getDocument('income_certificate')!;
      expect(updatedDoc.fileType, 'jpg');
      expect(updatedDoc.fileSize, 2048);
      expect(updatedDoc.storagePath, isNot(equals(oldPath)));

      // Verify old storage path was cleaned up
      expect(await service.getDocumentBytes(oldPath), isNull);
      // Verify new storage path exists
      expect(await service.getDocumentBytes(updatedDoc.storagePath), isNotNull);
    });

    test('deleteDocument purges metadata and storage file', () async {
      final service = DocumentService();
      final provider = UserDocumentProvider(service: service);
      const userId = 'citizen_del_test';

      final fileBytes = Uint8List.fromList(List.filled(1024, 1));
      await provider.uploadDocument(
        userId: userId,
        documentType: 'ration_card',
        documentName: 'Ration Card',
        fileName: 'ration.png',
        fileSize: 1024,
        fileBytes: fileBytes,
      );

      final doc = provider.getDocument('ration_card')!;
      expect(await service.getDocumentBytes(doc.storagePath), isNotNull);

      final deleted = await provider.deleteDocument(
        userId: userId,
        documentId: doc.documentId,
        documentType: doc.documentType,
        storagePath: doc.storagePath,
      );
      expect(deleted, isTrue);
      expect(provider.hasDocument('ration_card'), isFalse);
      expect(await service.getDocumentBytes(doc.storagePath), isNull);
    });

    testWidgets('MyDocumentsScreen renders empty state and loads with preselectedType shortcut',
        (WidgetTester tester) async {
      final docProvider = UserDocumentProvider();
      final authProvider = AuthProvider(authRepository: FakeTestAuthRepo());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => SchemeProvider()),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => EligibilityProvider()),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: docProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              SahayLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: SahayLocalizations.supportedLocales,
            home: const MyDocumentsScreen(preselectedType: 'caste_certificate'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state explanation
      expect(find.text('No Documents Uploaded Yet'), findsOneWidget);

      // Verify preselected modal opened automatically
      expect(find.text('Upload Document (Optional)'), findsOneWidget);
      expect(find.text('Choose File from Device'), findsOneWidget);
    });
  });
}

class FakeTestAuthRepo extends Fake implements AuthRepository {
  @override
  Stream<UserModel?> get currentUserProfileStream => Stream.value(null);
  @override
  Future<UserModel?> getCurrentUser() async => null;
}
