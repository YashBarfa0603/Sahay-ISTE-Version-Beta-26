import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/services/question_engine.dart';
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
  });
}
