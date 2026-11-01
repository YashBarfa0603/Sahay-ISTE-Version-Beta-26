import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/document_checklist_screen.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/my_documents_screen.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/results_screen.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';
import 'package:sahay/widgets/expandable_document_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(Widget child, Locale locale) {
    final auth = AuthProvider();
    auth.enterGuestMode();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(locale)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => SchemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => EligibilityProvider()),
        ChangeNotifierProvider(create: (_) => UserDocumentProvider()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          SahayLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: SahayLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('RenderFlex Overflow Regression Tests', () {
    testWidgets('Document Vault Card and Recommended Header in 360px width renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Document Vault Card using Wrap
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paleSage,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.folder_shared_rounded,
                                color: AppColors.forestGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Document Vault',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.deepNavy,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.forestGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Private & Encrypted',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.forestGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1 document securely saved. Tap to manage or add required documents.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recommended Schemes Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.deepNavy, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Recommended Schemes for You',
                                    style: AppTextStyles.heading3.copyWith(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Document Vault'), findsOneWidget);
      expect(find.text('Private & Encrypted'), findsOneWidget);
      expect(find.text('Recommended Schemes for You'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DocumentSpecimenViewer renders ration_card & samagra_id without overflow in 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final samagraDoc = DocumentCatalogueService.getDocumentByType('samagra_id')!;
      final rationDoc = DocumentCatalogueService.getDocumentByType('ration_card')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DocumentSpecimenViewer(documentInfo: samagraDoc, language: 'en'),
                  const SizedBox(height: 16),
                  DocumentSpecimenViewer(documentInfo: rationDoc, language: 'hi'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Samagra'), findsWidgets);
      expect(find.textContaining('Ration'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpandableDocumentCard renders and expands without overflow in narrow 320px constraint', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rationDoc = DocumentCatalogueService.getDocumentByType('ration_card')!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: ExpandableDocumentCard(
                  documentTitle: rationDoc.displayName,
                  isChecked: false,
                  onChecked: (_) {},
                  language: 'en',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);

      // Tap card to expand specimen and details
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(DocumentSpecimenViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    const screenSizes = [
      Size(360, 640),
      Size(375, 667),
      Size(390, 844),
      Size(412, 915),
    ];
    const keyLocales = ['en', 'hi', 'ta', 'mr'];

    for (final size in screenSizes) {
      for (final lang in keyLocales) {
        testWidgets('Responsive Screen Overflow Verification on ${size.width}x${size.height} in $lang', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // Test Welcome Screen
          await tester.pumpWidget(buildApp(const WelcomeScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test Home Screen
          await tester.pumpWidget(buildApp(const HomeScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test Results Screen
          await tester.pumpWidget(buildApp(const ResultsScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test My Documents Screen
          await tester.pumpWidget(buildApp(const MyDocumentsScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test Questionnaire Screen
          await tester.pumpWidget(buildApp(const QuestionnaireScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test Scheme Detail Screen
          final schemes = await const SchemeDataService().getAllSchemes();
          await tester.pumpWidget(buildApp(SchemeDetailScreen(scheme: schemes.first), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Test Document Checklist Screen
          await tester.pumpWidget(buildApp(const DocumentChecklistScreen(), Locale(lang)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
