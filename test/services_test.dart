import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/services/eligibility_engine.dart';
import 'package:sahay/services/privacy_service.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() {
  group('SchemeDataService Tests', () {
    const dataService = SchemeDataService();

    test('Loads 6 curated schemes with valid metadata and rules', () async {
      final schemes = await dataService.getAllSchemes();
      expect(schemes.length, 6);

      final schemeIds = schemes.map((s) => s.schemeId).toList();
      expect(schemeIds, containsAll([
        'pm-kisan',
        'pm-jay',
        'pmay-g',
        'ujjwala-2',
        'pm-scholarship',
        'ladli-behna-mp',
      ]));

      for (final scheme in schemes) {
        expect(scheme.name.isNotEmpty, true);
        expect(scheme.nameHindi != null, true);
        expect(scheme.description.isNotEmpty, true);
        expect(scheme.benefits.isNotEmpty, true);
        expect(scheme.officialSourceUrl.isNotEmpty, true);
        expect(scheme.requiredDocuments.isNotEmpty, true);
        expect(scheme.eligibilityRules.isNotEmpty, true);
      }
    });

    test('Searches schemes by keyword', () async {
      final results = await dataService.searchSchemes('kisan');
      expect(results.length, 1);
      expect(results.first.schemeId, 'pm-kisan');

      final mpResults = await dataService.searchSchemes('Madhya Pradesh');
      expect(mpResults.any((s) => s.schemeId == 'ladli-behna-mp'), true);
    });

    test('Filters schemes by category', () async {
      final agriculture = await dataService.getSchemesByCategory('agriculture');
      expect(agriculture.length, 1);
      expect(agriculture.first.schemeId, 'pm-kisan');

      final women = await dataService.getSchemesByCategory('women_welfare');
      expect(women.length, 2);
    });
  });

  group('EligibilityEngine Tests', () {
    const engine = EligibilityEngine();
    const dataService = SchemeDataService();

    test('PM-KISAN qualifies for farmer with <= 2ha land and bank account', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
        'landOwnership': 1.5,
        'hasBankAccount': true,
        'annualIncome': 120000,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.mayQualify);
      expect(result.missingInformation, isEmpty);
    });

    test('PM-KISAN fails when land > 2ha', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
        'landOwnership': 3.5,
        'hasBankAccount': true,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.doesNotQualify);
    });

    test('PM-KISAN returns needsMoreInformation when mandatory fields are missing', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.needsMoreInformation);
      expect(result.missingInformation, contains('landOwnership'));
      expect(result.missingInformation, contains('hasBankAccount'));
    });

    test('Detects borderline conditions within 10% of limit', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      // Limit is 2.0; 1.9 is within 10% (between 1.8 and 2.2)
      final answers = {
        'occupation': 'farmer',
        'landOwnership': 1.9,
        'hasBankAccount': true,
      };

      final result = engine.evaluateScheme(scheme, answers);
      final warnings = engine.detectBorderlineConditions(result, answers);
      expect(warnings.isNotEmpty, true);
      expect(warnings.first, contains('landOwnership'));
    });

    test('Ladli Behna Yojana MP qualifies for 30 yo woman in MP with income <= 2.5L', () async {
      final scheme = (await dataService.getSchemeById('ladli-behna-mp'))!;
      final answers = {
        'gender': 'female',
        'state': 'Madhya Pradesh',
        'age': 30,
        'annualIncome': 150000,
        'hasBankAccount': true,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.mayQualify);
    });
  });

  group('QuestionEngine Tests', () {
    const questionEngine = QuestionEngine();
    const dataService = SchemeDataService();

    test('Returns 16 base questions with labels', () {
      final questions = questionEngine.allQuestions;
      expect(questions.length, 16);
      expect(questions.first.id, 'gender');
    });

    test('Prioritizes questions with highest elimination power', () async {
      final schemes = await dataService.getAllSchemes();
      final currentAnswers = <String, dynamic>{};

      final nextQuestion = questionEngine.getNextQuestion(currentAnswers, schemes);
      expect(nextQuestion, isNotNull);
      expect(nextQuestion!.id, anyOf('gender', 'age', 'annualIncome', 'hasBankAccount'));
    });

    test('Skips landOwnership when occupation is not farmer', () async {
      final schemes = await dataService.getAllSchemes();
      final currentAnswers = <String, dynamic>{
        'gender': 'female',
        'occupation': 'salaried',
      };

      // Ensure landOwnership is never suggested because dependency (farmer) is unmet
      final nextQuestion = questionEngine.getNextQuestion(currentAnswers, schemes);
      expect(nextQuestion?.id, isNot('landOwnership'));
    });
  });

  group('PrivacyService Tests', () {
    final privacy = PrivacyService();

    test('Initial state has no personal data', () {
      expect(privacy.hasPersonalData(), false);
    });

    test('Stores and clears in-memory answers', () async {
      privacy.setSessionAnswer('gender', 'female');
      privacy.setSessionAnswer('annualIncome', 200000);
      expect(privacy.hasPersonalData(), true);

      await privacy.clearSessionData();
      expect(privacy.hasPersonalData(), false);
      expect(privacy.sessionAnswers, isEmpty);
    });

    test('Stores preferred language without affecting session answers', () {
      privacy.setPreferredLanguage('hi');
      expect(privacy.preferredLanguage, 'hi');
      expect(privacy.hasPersonalData(), false);
    });
  });
}
