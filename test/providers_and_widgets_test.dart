import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/services/eligibility_engine.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/confidence_badge.dart';
import 'package:sahay/widgets/eligibility_card.dart';
import 'package:sahay/widgets/language_toggle.dart';
import 'package:sahay/widgets/question_card.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:sahay/widgets/scheme_source_info.dart';
import 'package:sahay/widgets/voice_input_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider Tests', () {
    test('Initializes with default English locale', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, 'en');
      expect(provider.languageCode, 'en');
    });

    test('Correctly maps character assets according to exact filenames', () {
      final provider = LocaleProvider();
      expect(provider.getCharacterAsset('en'), 'assets/English.jpeg');
      expect(provider.getCharacterAsset('hi'), 'assets/Hindi.jpeg');
      expect(provider.getCharacterAsset('ta'), 'assets/Tamil.jpeg');
      expect(provider.getCharacterAsset('mr'), 'assets/Marathi.jpeg');
      expect(provider.getCharacterAsset('bn'), 'assets/Bangali.jpeg'); // Bangali requirement
      expect(provider.getCharacterAsset('gu'), 'assets/Gujarati.jpeg');
      expect(provider.getCharacterAsset('kn'), 'assets/Kannada.jpeg');
      expect(provider.getCharacterAsset('or'), 'assets/Odia.jpeg');
    });

    test('Correctly maps native language names', () {
      final provider = LocaleProvider();
      expect(provider.getNativeLanguageName('en'), 'English');
      expect(provider.getNativeLanguageName('hi'), 'हिन्दी');
      expect(provider.getNativeLanguageName('ta'), 'தமிழ்');
      expect(provider.getNativeLanguageName('mr'), 'मराठी');
      expect(provider.getNativeLanguageName('bn'), 'বাংলা');
      expect(provider.getNativeLanguageName('gu'), 'ગુજરાતી');
      expect(provider.getNativeLanguageName('kn'), 'ಕನ್ನಡ');
      expect(provider.getNativeLanguageName('or'), 'ଓଡ଼ିଆ');
    });

    test('Supports exactly 8 languages with metadata', () {
      final provider = LocaleProvider();
      expect(provider.supportedLanguages.length, 8);
    });

    test('Sets and persists locale to SharedPreferences', () async {
      final provider = LocaleProvider();
      await provider.setLocale(const Locale('hi'));
      expect(provider.languageCode, 'hi');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_language_code'), 'hi');
    });
  });

  group('UserProfileProvider Tests', () {
    test('Stores, updates, and retrieves answers correctly', () {
      final provider = UserProfileProvider();
      expect(provider.answeredCount, 0);
      expect(provider.hasAnswer('age'), false);

      provider.setAnswer('age', 35);
      expect(provider.answeredCount, 1);
      expect(provider.hasAnswer('age'), true);
      expect(provider.getAnswer('age'), 35);

      provider.setAnswer('occupation', 'farmer');
      expect(provider.answeredCount, 2);

      provider.removeAnswer('age');
      expect(provider.answeredCount, 1);
      expect(provider.hasAnswer('age'), false);

      provider.clearAllAnswers();
      expect(provider.answeredCount, 0);
    });
  });

  group('SchemeProvider Tests', () {
    test('Loads schemes from SchemeDataService and applies filters', () async {
      const dataService = SchemeDataService();
      final provider = SchemeProvider();

      await provider.loadSchemes(dataService);
      expect(provider.schemes.length, 6);
      expect(provider.filteredSchemes.length, 6);

      // Search filter
      provider.searchSchemes('kisan');
      expect(provider.filteredSchemes.length, 1);
      expect(provider.filteredSchemes.first.schemeId, 'pm-kisan');

      // Clear search
      provider.searchSchemes('');
      expect(provider.filteredSchemes.length, 6);

      // Filter by category
      provider.filterByCategory('healthcare');
      expect(provider.filteredSchemes.length, 1);
      expect(provider.filteredSchemes.first.schemeId, 'pm-jay');

      // Filter by level
      provider.filterByCategory(null);
      provider.filterByLevel(GovernmentLevel.state);
      expect(provider.filteredSchemes.length, 1);
      expect(provider.filteredSchemes.first.schemeId, 'ladli-behna-mp');

      // Clear all
      provider.clearFilters();
      expect(provider.filteredSchemes.length, 6);
    });
  });

  group('EligibilityProvider Tests', () {
    test('Evaluates all schemes and separates qualifying, needsInfo, and disqualified', () async {
      const dataService = SchemeDataService();
      final schemes = await dataService.getAllSchemes();

      final provider = EligibilityProvider();
      expect(provider.hasEvaluated, false);

      // Evaluate with full farmer answers
      provider.evaluateAll(schemes, {
        'occupation': 'farmer',
        'landOwnership': 1.5,
        'hasBankAccount': true,
        'annualIncome': 200000,
        'gender': 'male',
        'age': 32,
      });

      expect(provider.hasEvaluated, true);
      expect(provider.results.isNotEmpty, true);
      expect(provider.qualifyingSchemes.any((r) => r.schemeId == 'pm-kisan'), true);

      final result = provider.getResultForScheme('pm-kisan');
      expect(result, isNotNull);
      expect(result!.result, EligibilityResult.mayQualify);

      provider.clearResults();
      expect(provider.hasEvaluated, false);
      expect(provider.results.isEmpty, true);
    });
  });

  group('Widgets Widget Tests', () {
    testWidgets('ConfidenceBadge renders appropriate color and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(result: EligibilityResult.mayQualify),
          ),
        ),
      );

      expect(find.text('May Qualify'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('LanguageToggle opens modal bottom sheet with 8 languages', (tester) async {
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: localeProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: LanguageToggle(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget);

      // Scroll to view the remaining languages
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('ગુજરાતી'), findsOneWidget);
      expect(find.text('ಕನ್ನಡ'), findsOneWidget);
      expect(find.text('ଓଡ଼ିଆ'), findsOneWidget);
    });

    testWidgets('VoiceInputButton renders idle label and toggles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceInputButton(
              onResult: (text) {},
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Tap to speak'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('EligibilityCard displays scheme name and explanation', (tester) async {
      const dataService = SchemeDataService();
      final scheme = (await dataService.getAllSchemes()).first;
      final eligibility = const EligibilityEngine().evaluateScheme(scheme, {
        'occupation': 'farmer',
        'landOwnership': 1.0,
        'hasBankAccount': true,
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizations.delegate,
          ],
          home: Scaffold(
            body: EligibilityCard(
              scheme: scheme,
              eligibility: eligibility,
            ),
          ),
        ),
      );

      expect(find.text(scheme.name), findsOneWidget);
      expect(find.byType(ConfidenceBadge), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('QuestionCard renders single choice and boolean variants', (tester) async {
      const q = QuestionItem(
        id: 'gender',
        type: 'single_choice',
        options: ['male', 'female', 'other'],
        label: 'What is your gender?',
      );

      dynamic selectedVal;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizations.delegate,
          ],
          home: Scaffold(
            body: QuestionCard(
              question: q,
              currentAnswer: selectedVal,
              onAnswerChanged: (v) => selectedVal = v,
              onNext: () {},
            ),
          ),
        ),
      );

      expect(find.text('What is your gender?'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('SchemeSourceInfo displays source info and verified status', (tester) async {
      const dataService = SchemeDataService();
      final scheme = (await dataService.getAllSchemes()).first;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            SahayLocalizations.delegate,
          ],
          home: Scaffold(
            body: SchemeSourceInfo(scheme: scheme),
          ),
        ),
      );

      expect(find.text('Official Source'), findsOneWidget);
      expect(find.text(scheme.officialSourceUrl), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('SahayAppBar renders branding, title, and language toggle', (tester) async {
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: localeProvider,
          child: const MaterialApp(
            home: Scaffold(
              appBar: SahayAppBar(
                title: 'Schemes',
                showBackButton: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Schemes'), findsOneWidget);
      expect(find.text('SAHAY'), findsOneWidget);
      expect(find.byType(LanguageToggle), findsOneWidget);
    });
  });
}
