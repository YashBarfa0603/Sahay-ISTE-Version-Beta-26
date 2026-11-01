import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/schemes_screen.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(Widget child, {SchemeProvider? schemeProvider}) {
    final auth = AuthProvider();
    auth.enterGuestMode();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: schemeProvider ?? SchemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => EligibilityProvider()),
        ChangeNotifierProvider(create: (_) => UserDocumentProvider()),
      ],
      child: MaterialApp(
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

  group('Issue 1: Search Focus and Keyboard Dismissal Tests', () {
    testWidgets('SchemesScreen: submitting search query unfocuses text field and retains query', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(buildApp(const SchemesScreen(), schemeProvider: schemeProvider));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      expect(searchFieldFinder, findsOneWidget);

      // Focus the text field
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(searchFieldFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      // Enter query
      await tester.enterText(searchFieldFinder, 'Kisan');
      await tester.pumpAndSettle();

      // Submit query
      textFieldWidget.onSubmitted?.call('Kisan');
      await tester.pumpAndSettle();

      // Focus must be dismissed
      expect(textFieldWidget.focusNode?.hasFocus, isFalse);

      // Query must be preserved in controller
      expect(textFieldWidget.controller?.text, 'Kisan');
    });

    testWidgets('SchemesScreen: tapping search icon unfocuses text field and preserves query', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(buildApp(const SchemesScreen(), schemeProvider: schemeProvider));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(searchFieldFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      await tester.enterText(searchFieldFinder, 'Ayushman');
      await tester.pumpAndSettle();

      // Tap interactive search icon button
      final searchIconBtn = find.widgetWithIcon(IconButton, Icons.search_rounded);
      expect(searchIconBtn, findsOneWidget);

      await tester.tap(searchIconBtn);
      await tester.pumpAndSettle();

      // Focus dismissed and query retained
      expect(textFieldWidget.focusNode?.hasFocus, isFalse);
      expect(textFieldWidget.controller?.text, 'Ayushman');
    });

    testWidgets('SchemesScreen: tapping outside search field unfocuses text field', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(buildApp(const SchemesScreen(), schemeProvider: schemeProvider));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(searchFieldFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      // Tap on background outside search input
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();

      expect(textFieldWidget.focusNode?.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen: submitting search query unfocuses search field and retains query', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(buildApp(const HomeScreen(), schemeProvider: schemeProvider));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      expect(searchFieldFinder, findsOneWidget);

      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(searchFieldFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      await tester.enterText(searchFieldFinder, 'Awas');
      await tester.pumpAndSettle();

      textFieldWidget.onSubmitted?.call('Awas');
      await tester.pumpAndSettle();

      expect(textFieldWidget.focusNode?.hasFocus, isFalse);
      expect(textFieldWidget.controller?.text, 'Awas');
    });

    testWidgets('HomeScreen: tapping search icon button unfocuses and retains query', (tester) async {
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(const SchemeDataService());

      await tester.pumpWidget(buildApp(const HomeScreen(), schemeProvider: schemeProvider));
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(searchFieldFinder);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      await tester.enterText(searchFieldFinder, 'Ujjwala');
      await tester.pumpAndSettle();

      final searchIconBtn = find.widgetWithIcon(IconButton, Icons.search_rounded);
      expect(searchIconBtn, findsOneWidget);

      await tester.tap(searchIconBtn);
      await tester.pumpAndSettle();

      expect(textFieldWidget.focusNode?.hasFocus, isFalse);
      expect(textFieldWidget.controller?.text, 'Ujjwala');
    });
  });
}
