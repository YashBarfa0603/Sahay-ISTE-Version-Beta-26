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
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';
import 'package:sahay/services/privacy_service.dart';
import 'package:sahay/widgets/privacy_dialog.dart';

class MockAuthRepo extends Fake implements AuthRepository {
  UserModel? mockUser;

  @override
  Stream<UserModel?> get currentUserProfileStream => Stream.value(mockUser);

  @override
  Future<UserModel?> getCurrentUser() async => mockUser;

  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

Widget buildTestableApp({
  required AuthProvider authProvider,
  required UserProfileProvider userProfileProvider,
  required EligibilityProvider eligibilityProvider,
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => SchemeProvider()),
      ChangeNotifierProvider(create: (_) => UserDocumentProvider()),
      ChangeNotifierProvider.value(value: userProfileProvider),
      ChangeNotifierProvider.value(value: eligibilityProvider),
      ChangeNotifierProvider.value(value: authProvider),
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
      home: home ?? const HomeScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 — Authentication and Session Bug Fixes', () {
    testWidgets('Bug 1: End Session & Clear wipes state, resets guest, and returns to WelcomeScreen',
        (WidgetTester tester) async {
      final fakeRepo = MockAuthRepo();
      final authProvider = AuthProvider(authRepository: fakeRepo);
      authProvider.enterGuestMode();

      final userProfileProvider = UserProfileProvider();
      userProfileProvider.setAnswer('annualIncome', '150000');
      userProfileProvider.setAnswer('casteCategory', 'OBC');

      final eligibilityProvider = EligibilityProvider();

      final privacyService = PrivacyService();
      privacyService.setSessionAnswer('testKey', 'testVal');

      expect(authProvider.isGuest, isTrue);
      expect(userProfileProvider.answers.isNotEmpty, isTrue);
      expect(privacyService.hasPersonalData(), isTrue);

      await tester.pumpWidget(
        buildTestableApp(
          authProvider: authProvider,
          userProfileProvider: userProfileProvider,
          eligibilityProvider: eligibilityProvider,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => PrivacyDialog.showEndSessionConfirmation(ctx),
                  child: const Text('Open Privacy Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Privacy Dialog'));
      await tester.pumpAndSettle();

      // Tap End Session
      final endSessionBtn = find.text('End Session');
      expect(endSessionBtn, findsOneWidget);
      await tester.tap(endSessionBtn);
      await tester.pumpAndSettle();

      // Verify WelcomeScreen is displayed
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Verify all session data is wiped
      expect(userProfileProvider.answers.isEmpty, isTrue);
      expect(privacyService.hasPersonalData(), isFalse);
      expect(authProvider.isGuest, isFalse);

      // Verify back navigation is prevented (stack cleared, no route to pop)
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigatorState.canPop(), isFalse);
    });

    testWidgets('Bug 2: Log Out clears session state, auth state, and returns to WelcomeScreen',
        (WidgetTester tester) async {
      final fakeRepo = MockAuthRepo();
      fakeRepo.mockUser = UserModel(
        uid: 'user-123',
        email: 'test@sahay.gov.in',
        fullName: 'Ramesh Kumar',
        mobileNumber: '9876543210',
        profileComplete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(authRepository: fakeRepo);
      await tester.pump();

      final userProfileProvider = UserProfileProvider();
      userProfileProvider.setAnswer('annualIncome', '200000');
      final eligibilityProvider = EligibilityProvider();
      final privacyService = PrivacyService();
      privacyService.setSessionAnswer('tempPref', 'val');

      await tester.pumpWidget(
        buildTestableApp(
          authProvider: authProvider,
          userProfileProvider: userProfileProvider,
          eligibilityProvider: eligibilityProvider,
          home: const HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify HomeScreen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap Profile icon to open profile bottom sheet
      final profileNavIcon = find.byIcon(Icons.person_rounded);
      expect(profileNavIcon, findsOneWidget);
      await tester.tap(profileNavIcon);
      await tester.pumpAndSettle();

      // Find Log Out button
      final logoutBtn = find.text('Log Out');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Verify WelcomeScreen is displayed
      expect(find.byType(WelcomeScreen), findsOneWidget);

      // Verify auth state is cleared
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isGuest, isFalse);

      // Verify session data is cleared
      expect(userProfileProvider.answers.isEmpty, isTrue);
      expect(privacyService.hasPersonalData(), isFalse);

      // Verify back navigation cannot return to HomeScreen
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigatorState.canPop(), isFalse);
    });
  });
}
