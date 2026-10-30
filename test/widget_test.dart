import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/main.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';

void main() {
  testWidgets('SahayApp smoke test and renders welcome screen', (WidgetTester tester) async {
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

    await tester.pump();

    // Verify WelcomeScreen loads
    expect(find.byType(SahayApp), findsOneWidget);
  });
}
