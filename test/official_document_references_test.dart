import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 3: Official Document References & Specimen Zoom Tests', () {
    testWidgets('renders Aadhaar specimen with UIDAI and masked number', (tester) async {
      final docInfo = DocumentCatalogueService.getDocumentByType('aadhaar_card');
      expect(docInfo, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSpecimenViewer(documentInfo: docInfo!),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL SPECIMEN LAYOUT — FOR GUIDANCE ONLY'), findsOneWidget);
      expect(find.text('Unique Identification Authority of India (UIDAI)'), findsOneWidget);
      expect(find.text('XXXX  XXXX  1234'), findsOneWidget);
      expect(find.text('ZOOM'), findsOneWidget);
    });

    testWidgets('renders Samagra ID specimen with MP SSSM attributes', (tester) async {
      final docInfo = DocumentCatalogueService.getDocumentByType('samagra_id');
      expect(docInfo, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSpecimenViewer(documentInfo: docInfo!),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ZOOM'), findsOneWidget);
      expect(find.text('87654321'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget);
    });

    testWidgets('tapping ZOOM opens InteractiveViewer dialog', (tester) async {
      final docInfo = DocumentCatalogueService.getDocumentByType('aadhaar_card');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentSpecimenViewer(documentInfo: docInfo!),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the ZOOM button
      await tester.tap(find.text('ZOOM'));
      await tester.pumpAndSettle();

      // Verify that full-screen zoom dialog opened with InteractiveViewer
      expect(find.text('Full-Screen Specimen Inspection'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });
}

