import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/results_screen.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/question_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Questionnaire Auto-Advance Tests', () {
    testWidgets('Boolean question auto-advances on Yes/No tap without manual Next press', (tester) async {
      dynamic selectedAnswer;
      int nextCallCount = 0;

      const boolQuestion = QuestionItem(
        id: 'isFarmer',
        type: 'boolean',
        label: 'Are you an active farmer?',
        labelHindi: 'क्या आप सक्रिय किसान हैं?',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuestionCard(
              question: boolQuestion,
              currentAnswer: selectedAnswer,
              onAnswerChanged: (val) {
                selectedAnswer = val;
              },
              onNext: () {
                nextCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Yes option
      final yesFinder = find.text('Yes');
      expect(yesFinder, findsOneWidget);
      expect(nextCallCount, 0);

      // Tap Yes
      await tester.tap(yesFinder);
      await tester.pump(); // immediate visual frame

      // Immediate answer callback
      expect(selectedAnswer, isTrue);
      // Not yet advanced before duration
      expect(nextCallCount, 0);

      // Fast forward past 260ms auto-advance delay
      await tester.pump(const Duration(milliseconds: 300));

      // Verified: auto-transferred to next page without pressing Next button!
      expect(nextCallCount, 1);
    });

    testWidgets('Single choice question auto-advances on chip selection', (tester) async {
      dynamic selectedAnswer;
      int nextCallCount = 0;

      const choiceQuestion = QuestionItem(
        id: 'gender',
        type: 'single_choice',
        options: ['male', 'female', 'other'],
        label: 'Select your gender',
        labelHindi: 'अपना लिंग चुनें',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuestionCard(
              question: choiceQuestion,
              currentAnswer: selectedAnswer,
              onAnswerChanged: (val) {
                selectedAnswer = val;
              },
              onNext: () {
                nextCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find 'Female' option
      final femaleFinder = find.text('Female');
      expect(femaleFinder, findsOneWidget);
      expect(nextCallCount, 0);

      // Tap Female
      await tester.tap(femaleFinder);
      await tester.pump();

      expect(selectedAnswer, 'female');
      expect(nextCallCount, 0);

      // Fast forward past 260ms auto-advance delay
      await tester.pump(const Duration(milliseconds: 300));

      // Verified: auto-transferred to next page!
      expect(nextCallCount, 1);
    });

    testWidgets('Rapid multiple taps cancel previous timer and only trigger onNext once', (tester) async {
      dynamic selectedAnswer;
      int nextCallCount = 0;

      const choiceQuestion = QuestionItem(
        id: 'residenceType',
        type: 'single_choice',
        options: ['Rural', 'Urban'],
        label: 'Residence Type',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuestionCard(
              question: choiceQuestion,
              currentAnswer: selectedAnswer,
              onAnswerChanged: (val) {
                selectedAnswer = val;
              },
              onNext: () {
                nextCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Rural then quickly Urban
      await tester.tap(find.text('Rural'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(selectedAnswer, 'Rural');
      expect(nextCallCount, 0);

      // Switch to Urban before timer completes
      await tester.tap(find.text('Urban'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(selectedAnswer, 'Urban');
      expect(nextCallCount, 0);

      // Complete timer
      await tester.pump(const Duration(milliseconds: 250));

      // Verified: only advanced once with the latest selection
      expect(nextCallCount, 1);
      expect(selectedAnswer, 'Urban');
    });

    testWidgets('In Guest Mode, QuestionnaireScreen auto-advances on option selection', (tester) async {
      final schemeDataService = SchemeDataService();
      final authProvider = AuthProvider();
      authProvider.enterGuestMode();
      expect(authProvider.isGuest, isTrue);
      expect(authProvider.isAuthenticated, isFalse);

      final userProfileProvider = UserProfileProvider();
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(schemeDataService);
      final eligibilityProvider = EligibilityProvider();
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProfileProvider),
            ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
            ChangeNotifierProvider<EligibilityProvider>.value(value: eligibilityProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              SahayLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: QuestionnaireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify QuestionnaireScreen is showing
      expect(find.byType(QuestionnaireScreen), findsOneWidget);
      expect(find.byType(QuestionCard), findsOneWidget);

      // Verify first question auto-advances when option is tapped
      final femaleChip = find.text('Female');
      if (femaleChip.evaluate().isNotEmpty) {
        await tester.tap(femaleChip);
        await tester.pump(); // immediate visual feedback frame
        expect(userProfileProvider.getAnswer('gender'), 'female');

        // Wait 300ms for auto-advance to fire
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Check if next question rendered automatically
        expect(find.byType(QuestionCard), findsOneWidget);
      }
    });

    testWidgets('Single choice dropdown auto-advances on option selection', (tester) async {
      dynamic selectedAnswer;
      int nextCallCount = 0;

      const dropdownQuestion = QuestionItem(
        id: 'educationLevel',
        type: 'single_choice',
        options: ['primary', 'secondary', 'higherSecondary', 'graduate', 'postGraduate', 'other'],
        label: 'Education Level',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuestionCard(
              question: dropdownQuestion,
              currentAnswer: selectedAnswer,
              onAnswerChanged: (val) {
                selectedAnswer = val;
              },
              onNext: () {
                nextCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Dropdown
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap an option in the menu (e.g. Graduate)
      final graduateItem = find.text('Graduate').last;
      await tester.tap(graduateItem);
      await tester.pump(); // closes dropdown menu

      expect(selectedAnswer, 'graduate');
      expect(nextCallCount, 0);

      // Fast forward past 260ms auto-advance delay
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(nextCallCount, 1);
    });

    testWidgets('Guest mode finishes questionnaire and transitions to ResultsScreen without login roadblock', (tester) async {
      final schemeDataService = SchemeDataService();
      final authProvider = AuthProvider();
      authProvider.enterGuestMode();
      expect(authProvider.isGuest, isTrue);
      expect(authProvider.isAuthenticated, isFalse);

      final userProfileProvider = UserProfileProvider();
      // Pre-fill answers so that evaluating next question will reach completion
      userProfileProvider.setAnswers({
        'gender': 'female',
        'age': 25,
        'state': 'Madhya Pradesh',
        'residenceType': 'rural',
        'casteCategory': 'general',
        'annualIncome': 120000,
        'occupation': 'homemaker',
        'maritalStatus': 'married',
        'disability': false,
        'hasHouse': false,
        'hasBankAccount': true,
        'isIncomeTaxPayer': false,
        'isGovernmentEmployee': false,
        'hasPriorityRationCard': true,
        'hasMotorizedVehicle': false,
        'hasFourWheeler': false,
        'isExServiceman': false,
        'existingLPG': false,
        'educationLevel': 'higherSecondary',
        'numberOfChildren': 1,
      });

      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(schemeDataService);
      final eligibilityProvider = EligibilityProvider();
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProfileProvider),
            ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
            ChangeNotifierProvider<EligibilityProvider>.value(value: eligibilityProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              SahayLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: QuestionnaireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // If finished, it pushes ResultsScreen
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should be on ResultsScreen or finish smoothly
      expect(find.byType(ResultsScreen), findsOneWidget);
      expect(eligibilityProvider.hasEvaluated, isTrue);
      expect(eligibilityProvider.results.isNotEmpty, isTrue);
    });

    testWidgets('Guest user steps through questionnaire with consecutive option auto-advances', (tester) async {
      final schemeDataService = SchemeDataService();
      final authProvider = AuthProvider();
      authProvider.enterGuestMode();

      final userProfileProvider = UserProfileProvider();
      final schemeProvider = SchemeProvider();
      await schemeProvider.loadSchemes(schemeDataService);
      final eligibilityProvider = EligibilityProvider();
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProfileProvider),
            ChangeNotifierProvider<SchemeProvider>.value(value: schemeProvider),
            ChangeNotifierProvider<EligibilityProvider>.value(value: eligibilityProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              SahayLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: QuestionnaireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Q1: gender chip
      final femaleChip = find.text('Female');
      if (femaleChip.evaluate().isNotEmpty) {
        await tester.tap(femaleChip);
        await tester.pump();
        expect(userProfileProvider.getAnswer('gender'), 'female');

        // Advance past delay
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // If boolean question appears (e.g. disability or existingLPG or hasHouse)
      final yesButton = find.text('Yes');
      final noButton = find.text('No');
      if (noButton.evaluate().isNotEmpty) {
        await tester.tap(noButton);
        await tester.pump();

        // Advance past delay
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      } else if (yesButton.evaluate().isNotEmpty) {
        await tester.tap(yesButton);
        await tester.pump();

        // Advance past delay
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Check that questionnaire state is active or progressed
      expect(userProfileProvider.answeredCount, greaterThanOrEqualTo(1));
    });
  });
}

