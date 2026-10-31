import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';
import 'package:sahay/widgets/expandable_document_card.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {
  UserModel? mockUser;
  _FakeAuthRepo({this.mockUser});

  @override
  Stream<UserModel?> get currentUserProfileStream => Stream.value(mockUser);
  @override
  Future<UserModel?> getCurrentUser() async => mockUser;
  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RenderFlex Overflow Regression Tests', () {
    testWidgets('HomeScreen on narrow phone (360x640) with logged-in user renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authedUser = UserModel(
        uid: 'test_user_1',
        fullName: 'Ramesh Sharma',
        email: 'ramesh@example.com',
        mobileNumber: '+919876543210',
        age: 35,
        gender: 'male',
        occupation: 'farmer',
        state: 'MP',
        profileComplete: true,
      );

      final authRepo = _FakeAuthRepo(mockUser: authedUser);
      final authProvider = AuthProvider(authRepository: authRepo);
      await tester.pump(const Duration(milliseconds: 50));

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadFullCatalogue();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
            ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
            ChangeNotifierProvider<UserDocumentProvider>(create: (_) => UserDocumentProvider()),
            ChangeNotifierProvider<UserProfileProvider>(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider<EligibilityProvider>(create: (_) => EligibilityProvider()),
            ChangeNotifierProvider<ApplicationProvider>(create: (_) => ApplicationProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              SahayLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: HomeScreen(),
          ),
        ),
      );

      // Use discrete pumps instead of pumpAndSettle to avoid waiting on continuous animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Document Vault card is present
      expect(find.text('Document Vault'), findsOneWidget);
      expect(find.text('Private & Encrypted'), findsOneWidget);

      // Verify Recommended Schemes section is present
      expect(find.text('Recommended Schemes for You'), findsOneWidget);

      // Verify no RenderFlex overflow exception was caught
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
                  const SizedBox(height: 10),
                  DocumentSpecimenViewer(documentInfo: samagraDoc, language: 'hi'),
                  const SizedBox(height: 10),
                  DocumentSpecimenViewer(documentInfo: rationDoc, language: 'en'),
                  const SizedBox(height: 10),
                  DocumentSpecimenViewer(documentInfo: rationDoc, language: 'hi'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpandableDocumentCard expands without overflow in narrow 320px constraint', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpandableDocumentCard(
                documentTitle: 'ration_card',
                isChecked: false,
                onChecked: (_) {},
                language: 'en',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap to expand - find by type or InkWell
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify expanded content is visible and no overflow occurred
      expect(find.text('Upload to Vault (Optional)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
