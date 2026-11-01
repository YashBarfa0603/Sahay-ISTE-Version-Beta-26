import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/screens/scheme_missing_info_screen.dart';
import 'package:sahay/services/eligibility_engine.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/eligibility_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemeDataService schemeService;
  late List<SchemeModel> allSchemes;
  late SchemeModel pmKisan;

  setUpAll(() async {
    schemeService = const SchemeDataService();
    allSchemes = await schemeService.getAllSchemes();
    pmKisan = allSchemes.firstWhere((s) => s.schemeId == 'pm-kisan');
  });

  Widget buildApp(
    Widget child, {
    UserProfileProvider? profileProvider,
    EligibilityProvider? eligibilityProvider,
    SchemeProvider? schemeProvider,
  }) {
    final auth = AuthProvider();
    auth.enterGuestMode();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: schemeProvider ?? SchemeProvider()),
        ChangeNotifierProvider.value(value: profileProvider ?? UserProfileProvider()),
        ChangeNotifierProvider.value(value: eligibilityProvider ?? EligibilityProvider()),
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

  group('Issue 2: QuestionEngine Missing Questions Resolution Tests', () {
    test('getMissingQuestionsForScheme asks ONLY for unanswered missing criteria', () {
      const engine = QuestionEngine();

      // Initial answers: age, state, occupation provided, but land ownership is missing
      final partialAnswers = {
        'age': 35,
        'state': 'MP',
        'occupation': 'farmer',
      };

      final missing = engine.getMissingQuestionsForScheme(pmKisan, partialAnswers);

      // Must ask for land ownership
      expect(missing.any((q) => q.id == 'landOwnership'), isTrue);

      // Must NEVER ask for already answered questions: age, state, occupation
      expect(missing.any((q) => q.id == 'age'), isFalse);
      expect(missing.any((q) => q.id == 'state'), isFalse);
      expect(missing.any((q) => q.id == 'occupation'), isFalse);
    });

    test('getMissingQuestionsForScheme returns empty when all criteria answered', () {
      const engine = QuestionEngine();

      final completeAnswers = {
        'age': 35,
        'state': 'MP',
        'occupation': 'farmer',
        'landOwnership': 1.5,
        'ownsCultivableLand': true,
        'hasBankAccount': true,
        'isIncomeTaxPayer': false,
        'isGovernmentEmployee': false,
        'isInstitutionalLandholder': false,
      };

      final missing = engine.getMissingQuestionsForScheme(pmKisan, completeAnswers);
      expect(missing.isEmpty, isTrue);
    });
  });

  group('Issue 2: SchemeMissingInfoScreen Widget Tests', () {
    testWidgets('Renders scheme name and ONLY the missing fields', (tester) async {
      final profileProvider = UserProfileProvider();
      profileProvider.setAnswers({
        'age': 40,
        'state': 'MP',
        'occupation': 'farmer',
      });

      final eligibilityEngine = const EligibilityEngine();
      final eval = eligibilityEngine.evaluateScheme(pmKisan, profileProvider.answers);
      expect(eval.result, EligibilityResult.needsMoreInformation);

      await tester.pumpWidget(
        buildApp(
          SchemeMissingInfoScreen(scheme: pmKisan, eligibility: eval),
          profileProvider: profileProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Scheme title is displayed prominently
      expect(find.text(pmKisan.name), findsOneWidget);

      // Land ownership question is present
      expect(find.textContaining(RegExp(r'land', caseSensitive: false)), findsWidgets);

      // Age, Gender, State questions are NOT asked again
      expect(find.text('What is your age?'), findsNothing);
      expect(find.text('Select your State or Union Territory'), findsNothing);
    });

    testWidgets('Empty submission fails validation with prompt', (tester) async {
      final profileProvider = UserProfileProvider();
      profileProvider.setAnswers({
        'age': 40,
        'state': 'MP',
        'occupation': 'farmer',
      });

      final eligibilityEngine = const EligibilityEngine();
      final eval = eligibilityEngine.evaluateScheme(pmKisan, profileProvider.answers);

      await tester.pumpWidget(
        buildApp(
          SchemeMissingInfoScreen(scheme: pmKisan, eligibility: eval),
          profileProvider: profileProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit without filling missing field
      final submitBtn = find.text('Submit & Check Eligibility');
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Validation prompt appears
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('Submitting missing information updates profile and re-evaluates scheme eligibility', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profileProvider = UserProfileProvider();
      profileProvider.setAnswers({
        'age': 40,
        'state': 'MP',
        'occupation': 'farmer',
      });

      final eligibilityProvider = EligibilityProvider();
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(schemeService);

      final initialEval = eligibilityProvider.evaluateSingle(pmKisan, profileProvider.answers);
      expect(initialEval.result, EligibilityResult.needsMoreInformation);

      await tester.pumpWidget(
        buildApp(
          SchemeMissingInfoScreen(scheme: pmKisan, eligibility: initialEval),
          profileProvider: profileProvider,
          eligibilityProvider: eligibilityProvider,
          schemeProvider: schemeProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Fill in land ownership field (number input)
      final numberFieldFinder = find.byType(TextFormField).first;
      await tester.enterText(numberFieldFinder, '1.5');
      await tester.pumpAndSettle();

      // If there are boolean choices (e.g. government employee exclusion), answer them
      final noTiles = find.text('No');
      for (final noFinder in noTiles.evaluate()) {
        await tester.tap(find.byWidget(noFinder.widget));
        await tester.pumpAndSettle();
      }

      // Tap submit
      final submitBtn = find.text('Submit & Check Eligibility');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify UserProfileProvider has the new answer while preserving existing answers
      expect(profileProvider.getAnswer('landOwnership'), 1.5);
      expect(profileProvider.getAnswer('age'), 40);
      expect(profileProvider.getAnswer('state'), 'MP');
      expect(profileProvider.getAnswer('occupation'), 'farmer');

      // Verify scheme is re-evaluated and no longer needs more info
      final updatedResult = eligibilityProvider.getResultForScheme(pmKisan.schemeId);
      expect(updatedResult, isNotNull);
      expect(updatedResult!.result != EligibilityResult.needsMoreInformation, isTrue);
    });

    testWidgets('Cancel button dismisses without modifying profile answers', (tester) async {
      final profileProvider = UserProfileProvider();
      profileProvider.setAnswers({
        'age': 30,
        'state': 'DL',
      });

      final eval = const EligibilityEngine().evaluateScheme(pmKisan, profileProvider.answers);

      await tester.pumpWidget(
        buildApp(
          SchemeMissingInfoScreen(scheme: pmKisan, eligibility: eval),
          profileProvider: profileProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Cancel
      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);

      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Answers untouched
      expect(profileProvider.answers.length, 2);
      expect(profileProvider.answers.containsKey('landOwnership'), isFalse);
    });
  });

  group('Issue 2: EligibilityCard & SchemeDetailScreen Navigation Routing Tests', () {
    testWidgets('EligibilityCard: "Provide Additional Information" button opens SchemeMissingInfoScreen', (tester) async {
      final eval = const EligibilityEngine().evaluateScheme(pmKisan, {'age': 30});
      expect(eval.result, EligibilityResult.needsMoreInformation);

      await tester.pumpWidget(
        buildApp(
          Scaffold(
            body: EligibilityCard(
              scheme: pmKisan,
              eligibility: eval,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button exists on card
      final provideInfoBtn = find.widgetWithText(OutlinedButton, 'Provide Additional Information');
      expect(provideInfoBtn, findsOneWidget);

      // Tap button
      await tester.tap(provideInfoBtn);
      await tester.pumpAndSettle();

      // Must navigate to SchemeMissingInfoScreen (NOT QuestionnaireScreen!)
      expect(find.byType(SchemeMissingInfoScreen), findsOneWidget);
      expect(find.byType(QuestionnaireScreen), findsNothing);
    });

    testWidgets('SchemeDetailScreen: "Provide Missing Information" button opens SchemeMissingInfoScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eval = const EligibilityEngine().evaluateScheme(pmKisan, {'age': 30});
      expect(eval.result, EligibilityResult.needsMoreInformation);

      final eligibilityProvider = EligibilityProvider();
      eligibilityProvider.evaluateSingle(pmKisan, {'age': 30});

      await tester.pumpWidget(
        buildApp(
          SchemeDetailScreen(
            scheme: pmKisan,
            eligibility: eval,
          ),
          eligibilityProvider: eligibilityProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Eligibility Tab (Tab index 1)
      final eligibilityTab = find.text('Eligibility');
      expect(eligibilityTab, findsWidgets);
      await tester.tap(eligibilityTab.first);
      await tester.pumpAndSettle();

      // Find "Provide Missing Information" / "Provide Additional Information" button
      final actionBtn = find.widgetWithIcon(ElevatedButton, Icons.edit_note_rounded);
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // Must open SchemeMissingInfoScreen (NOT QuestionnaireScreen!)
      expect(find.byType(SchemeMissingInfoScreen), findsOneWidget);
      expect(find.byType(QuestionnaireScreen), findsNothing);
    });
  });
}
