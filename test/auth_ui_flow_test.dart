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
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/screens/auth/auth_gate.dart';
import 'package:sahay/screens/auth/login_screen.dart';
import 'package:sahay/screens/auth/signup_screen.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/profile/profile_setup_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';

// Fake auth repository for widget testing
class FakeTestAuthRepository extends Fake implements AuthRepository {
  UserModel? mockUser;

  @override
  Stream<UserModel?> get currentUserProfileStream => Stream.value(mockUser);

  @override
  Future<UserModel?> getCurrentUser() async => mockUser;

  @override
  Future<void> signOut() async {
    mockUser = null;
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    if (mockUser != null) {
      mockUser = mockUser!.copyWith(
        age: fields['age'] is int ? fields['age'] as int : null,
        state: fields['state']?.toString(),
        district: fields['district']?.toString(),
        occupation: fields['occupation']?.toString(),
        preferredLanguage: fields['preferredLanguage']?.toString(),
        profileComplete: fields['profileComplete'] as bool? ?? true,
      );
    }
  }
}

Widget createTestApp({
  required AuthProvider authProvider,
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => SchemeProvider()),
      ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ChangeNotifierProvider(create: (_) => EligibilityProvider()),
      ChangeNotifierProvider.value(value: authProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.getTheme('en'),
      supportedLocales: SahayLocalizations.supportedLocales,
      localizationsDelegates: const [
        SahayLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home ?? const AuthGate(),
    ),
  );
}

void main() {
  group('Phase C - Auth & Navigation UI Tests', () {
    testWidgets('1. AuthGate routes unauthenticated non-guest to WelcomeScreen', (tester) async {
      final fakeRepo = FakeTestAuthRepository()..mockUser = null;
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('2. AuthGate routes guest mode to HomeScreen with guest banner', (tester) async {
      final fakeRepo = FakeTestAuthRepository()..mockUser = null;
      final authProvider = AuthProvider(authRepository: fakeRepo)..enterGuestMode();

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Guest mode: Sign in'), findsOneWidget);
    });

    testWidgets('3. AuthGate routes incomplete profile to ProfileSetupScreen', (tester) async {
      final incompleteUser = UserModel(
        uid: 'user_incomplete_123',
        fullName: 'New Citizen',
        email: 'new@example.com',
        mobileNumber: '9876543210',
        profileComplete: false,
      );
      final fakeRepo = FakeTestAuthRepository()..mockUser = incompleteUser;
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('4. AuthGate routes complete profile to HomeScreen', (tester) async {
      final completeUser = UserModel(
        uid: 'user_complete_456',
        fullName: 'Priyansh Shrivastav',
        email: 'priyansh@example.com',
        mobileNumber: '9876543210',
        age: 28,
        state: 'MP',
        district: 'Bhopal',
        occupation: 'farmer',
        preferredLanguage: 'en',
        profileComplete: true,
      );
      final fakeRepo = FakeTestAuthRepository()..mockUser = completeUser;
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(authProvider: authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Priyansh!'), findsOneWidget);
    });

    testWidgets('5. LoginScreen validates inputs and handles navigation to Signup', (tester) async {
      final fakeRepo = FakeTestAuthRepository();
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        authProvider: authProvider,
        home: const LoginScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap Sign In with empty fields -> shows validation errors
      final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      // Scroll to Sign Up link and tap
      final signUpLink = find.text('Sign Up');
      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('6. SignupScreen disables submit until terms are accepted', (tester) async {
      final fakeRepo = FakeTestAuthRepository();
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        authProvider: authProvider,
        home: const SignupScreen(),
      ));
      await tester.pumpAndSettle();

      final createAccountFinder = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createAccountFinder);
      final createAccountBtn = tester.widget<ElevatedButton>(createAccountFinder);
      expect(createAccountBtn.onPressed, isNull);

      // Scroll to and tap terms rich text gesture detector
      final termsFinder = find.textContaining('Terms of Service');
      await tester.ensureVisible(termsFinder);
      await tester.tap(termsFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('1. SAHAY is a welfare scheme discovery assistant'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      // Check the consent checkbox
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final enabledBtn = tester.widget<ElevatedButton>(createAccountFinder);
      expect(enabledBtn.onPressed, isNotNull);
    });

    testWidgets('7. ProfileSetupScreen updates profile and transitions when saved', (tester) async {
      final incompleteUser = UserModel(
        uid: 'user_setup_789',
        fullName: 'Test Setup User',
        email: 'setup@example.com',
        mobileNumber: '9876543210',
        profileComplete: false,
      );
      final fakeRepo = FakeTestAuthRepository()..mockUser = incompleteUser;
      final authProvider = AuthProvider(authRepository: fakeRepo);

      await tester.pumpWidget(createTestApp(
        authProvider: authProvider,
        home: const AuthGate(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      final success = await authProvider.updateProfile({
        'age': 30,
        'state': 'MP',
        'district': 'Bhopal',
        'occupation': 'farmer',
        'preferredLanguage': 'en',
        'profileComplete': true,
      });

      expect(success, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
