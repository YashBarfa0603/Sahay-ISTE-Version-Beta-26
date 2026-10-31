import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_theme.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/firebase_options.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/screens/auth/auth_gate.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // Firebase
  Object? initializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase init error: $e\n$stack');
    initializationError = e;
  }

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: SahayApp(initializationError: initializationError),
    ),
  );
}

class SahayApp extends StatelessWidget {
  final Object? initializationError;
  final Widget? home;

  const SahayApp({super.key, this.initializationError, this.home});

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
      home: initializationError != null
          ? _FirebaseErrorScreen(error: initializationError!)
          : (home ?? const AuthGate()),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final Object error;

  const _FirebaseErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to initialize Firebase services. Please check network connectivity or configuration.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
