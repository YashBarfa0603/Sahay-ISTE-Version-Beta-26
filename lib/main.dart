import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_theme.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // Schemes
  final schemeDataService = SchemeDataService();
  final schemeProvider = SchemeProvider();
  await schemeProvider.loadSchemes(schemeDataService);

  runApp(
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
}

class SahayApp extends StatelessWidget {
  const SahayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final languageCode = localeProvider.languageCode;

    return MaterialApp(
      title: 'SAHAY — सहाय',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(languageCode),
      locale: localeProvider.locale,
      supportedLocales: SahayLocalizations.supportedLocales,
      localizationsDelegates: const [
        SahayLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const WelcomeScreen(),
    );
  }
}
