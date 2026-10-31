import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/main.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/auth/login_screen.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen Get Started navigates to LoginScreen and Guest navigates to HomeScreen',
      (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    final schemeProvider = SchemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: schemeProvider),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => EligibilityProvider()),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const SahayApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify WelcomeScreen is displayed
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Tap Get Started button -> opens LoginScreen
    final getStartedButton = find.byType(ElevatedButton);
    expect(getStartedButton, findsOneWidget);
    await tester.tap(getStartedButton);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    // From LoginScreen, tap Continue as Guest
    final guestButton = find.text('Continue as Guest');
    expect(guestButton, findsOneWidget);
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    // Verify HomeScreen renders with BottomNavigationBar successfully
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
