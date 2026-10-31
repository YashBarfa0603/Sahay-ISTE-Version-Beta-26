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

    test('PM-KISAN qualifies for farmer with cultivable land and no disqualifications', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
        'landOwnership': 3.5, // > 2ha now qualifies (cap abolished in June 2019)
        'ownsCultivableLand': true,
        'isInstitutionalLandholder': false,
        'isGovernmentEmployee': false,
        'isIncomeTaxPayer': false,
        'hasBankAccount': true,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.mayQualify);
      expect(result.missingInformation, isEmpty);
    });

    test('PM-KISAN fails when farmer is income tax payer or government employee', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
        'ownsCultivableLand': true,
        'isIncomeTaxPayer': true,
        'isGovernmentEmployee': false,
        'isInstitutionalLandholder': false,
        'hasBankAccount': true,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.doesNotQualify);
    });

    test('PM-KISAN returns needsMoreInformation when mandatory exclusion fields are missing', () async {
      final scheme = (await dataService.getSchemeById('pm-kisan'))!;
      final answers = {
        'occupation': 'farmer',
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.needsMoreInformation);
      expect(result.missingInformation, contains('ownsCultivableLand'));
      expect(result.missingInformation, contains('isIncomeTaxPayer'));
    });

    test('Detects borderline conditions within 10% of limit', () async {
      final scheme = (await dataService.getSchemeById('ladli-behna-mp'))!;
      // Income limit is 250,000; 245,000 is within 10%
      final answers = {
        'gender': 'female',
        'state': 'Madhya Pradesh',
        'age': 30,
        'maritalStatus': 'married',
        'annualIncome': 245000,
        'hasBankAccount': true,
        'isIncomeTaxPayer': false,
        'hasFourWheeler': false,
        'isGovernmentEmployee': false,
      };

      final result = engine.evaluateScheme(scheme, answers);
      final warnings = engine.detectBorderlineConditions(result, answers);
      expect(warnings.isNotEmpty, true);
      expect(warnings.first, contains('annualIncome'));
    });

    test('Ladli Behna Yojana MP qualifies for 30 yo married woman in MP with income <= 2.5L and no exclusions', () async {
      final scheme = (await dataService.getSchemeById('ladli-behna-mp'))!;
      final answers = {
        'gender': 'female',
        'state': 'Madhya Pradesh',
        'age': 30,
        'maritalStatus': 'married',
        'annualIncome': 150000,
        'hasBankAccount': true,
        'isIncomeTaxPayer': false,
        'hasFourWheeler': false,
        'isGovernmentEmployee': false,
      };

      final result = engine.evaluateScheme(scheme, answers);
      expect(result.result, EligibilityResult.mayQualify);
    });
  });

  group('QuestionEngine Tests', () {
    const questionEngine = QuestionEngine();
    const dataService = SchemeDataService();

    test('Returns 23 base questions with labels', () {
      final questions = questionEngine.allQuestions;
      expect(questions.length, 23);
      expect(questions.first.id, 'gender');
    });

    test('Detects contradiction between conflicting answers and stops question flow', () async {
      final schemes = await dataService.getAllSchemes();

      // Conflicting age and marital status (minor married)
      final conflictingAnswers = <String, dynamic>{
        'age': 14,
        'maritalStatus': 'married',
      };

      final contradictions = questionEngine.detectContradictions(conflictingAnswers);
      expect(contradictions.isNotEmpty, true);
      expect(contradictions.first.isBlocking, true);
      expect(contradictions.first.conflictingFields, contains('age'));
      expect(contradictions.first.conflictingFields, contains('maritalStatus'));

      // QuestionEngine must stop asking questions when a blocking contradiction occurs
      final nextQuestion = questionEngine.getNextQuestion(conflictingAnswers, schemes);
      expect(nextQuestion, isNull);
    });

    test('Detects contradiction between high income and BPL card', () {
      final answers = <String, dynamic>{
        'annualIncome': 500000,
        'hasPriorityRationCard': true,
      };

      final contradictions = questionEngine.detectContradictions(answers);
      expect(contradictions.isNotEmpty, true);
      expect(contradictions.any((c) => c.conflictingFields.contains('hasPriorityRationCard')), true);
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
