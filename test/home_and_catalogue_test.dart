import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_theme.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/schemes_screen.dart';
import 'package:sahay/services/document_service.dart';
import 'package:sahay/services/scheme_data_service.dart';

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

  group('Phase 3 — Catalogue and Home Screen Restructuring Tests', () {
    test('Complete catalogue contains 100 schemes and loads via SchemeDataService', () async {
      final service = SchemeDataService();
      final catalogue = await service.getCompleteCatalogue();
      expect(catalogue.length, equals(100));

      final central = catalogue.where((s) => s.governmentLevel == GovernmentLevel.central).length;
      final state = catalogue.where((s) => s.governmentLevel == GovernmentLevel.state).length;
      expect(central, equals(60));
      expect(state, equals(40));
    });

    test('SchemeProvider state filtering includes central and matching state schemes', () async {
      final provider = SchemeProvider();
      await provider.loadFullCatalogue();

      expect(provider.totalSchemesCount, equals(100));

      // Filter by Madhya Pradesh ('MP')
      provider.filterByState('MP');
      final mpSchemes = provider.filteredSchemes;

      // Every returned scheme must either be central (All-India) or have 'MP' in applicableStates
      for (final s in mpSchemes) {
        final isCentral = s.governmentLevel == GovernmentLevel.central ||
            s.applicableStates.contains('ALL_INDIA');
        final isMP = s.applicableStates.contains('MP');
        expect(isCentral || isMP, isTrue);
      }

      // Check Assam schemes are not among the state-specific schemes when filtered by MP
      final assamStateSchemes = mpSchemes.where(
        (s) => s.governmentLevel == GovernmentLevel.state && s.applicableStates.contains('AS'),
      );
      expect(assamStateSchemes.isEmpty, isTrue);

      // Clear filters returns all 100
      provider.clearFilters();
      expect(provider.filteredSchemesCount, equals(100));
    });

    Widget createTestApp({
      required AuthProvider authProvider,
      required SchemeProvider schemeProvider,
      required UserDocumentProvider docProvider,
      required Widget homeWidget,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
          ChangeNotifierProvider<UserDocumentProvider>.value(value: docProvider),
          ChangeNotifierProvider<UserProfileProvider>(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider<EligibilityProvider>(create: (_) => EligibilityProvider()),
          ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
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
          home: homeWidget,
        ),
      );
    }

    testWidgets('HomeScreen: Document Vault card shown for authenticated user and hidden for guest', (tester) async {
      final authedUser = UserModel(
        uid: 'user_123',
        fullName: 'Ramesh Kumar',
        mobileNumber: '9876543210',
        email: 'ramesh@example.com',
        createdAt: DateTime.now(),
        profileComplete: true,
      );
      final authRepo = _FakeAuthRepo(mockUser: authedUser);
      final authProvider = AuthProvider(authRepository: authRepo);
      // Wait for auth provider initial profile stream
      await tester.pump(const Duration(milliseconds: 50));

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadFullCatalogue();

      final docService = DocumentService();
      final docProvider = UserDocumentProvider(service: docService);

      await tester.pumpWidget(createTestApp(
        authProvider: authProvider,
        schemeProvider: schemeProvider,
        docProvider: docProvider,
        homeWidget: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      // Document Vault card must be visible for authenticated user
      expect(find.text('Document Vault'), findsOneWidget);
      expect(find.text('Private & Encrypted'), findsOneWidget);

      // Eligibility CTA must also be present
      expect(find.text('Check Your Eligibility'), findsOneWidget);

      // 2. Switch to Guest Mode
      authProvider.enterGuestMode();
      await tester.pumpAndSettle();

      // Document Vault card must be hidden for guest user
      expect(find.text('Document Vault'), findsNothing);
      expect(find.text('Private & Encrypted'), findsNothing);

      // Eligibility CTA must remain present
      expect(find.text('Check Your Eligibility'), findsOneWidget);
    });

    testWidgets('SchemesScreen: renders full catalogue with Check Eligibility and View Details actions', (tester) async {
      final authRepo = _FakeAuthRepo();
      final authProvider = AuthProvider(authRepository: authRepo);
      authProvider.enterGuestMode();

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadFullCatalogue();

      final docProvider = UserDocumentProvider(service: DocumentService());

      await tester.pumpWidget(createTestApp(
        authProvider: authProvider,
        schemeProvider: schemeProvider,
        docProvider: docProvider,
        homeWidget: const SchemesScreen(),
      ));
      await tester.pumpAndSettle();

      // Indicator shows schemes found (100 schemes)
      expect(find.text('100 Schemes found'), findsOneWidget);

      // Buttons inside cards
      expect(find.text('Check Eligibility'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });
  });
}
