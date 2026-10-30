import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/main.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen Get Started navigates to HomeScreen without MaterialLocalizations error',
      (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    final schemeProvider = SchemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: schemeProvider),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => EligibilityProvider()),
        ],
        child: const SahayApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify WelcomeScreen is displayed
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Tap Get Started button
    final getStartedButton = find.byType(ElevatedButton);
    expect(getStartedButton, findsOneWidget);
    await tester.tap(getStartedButton);

    await tester.pumpAndSettle();

    // Verify HomeScreen renders with BottomNavigationBar successfully
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}

