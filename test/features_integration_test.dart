import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/api_response_models.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/services/backend_scheme_service.dart';
import 'package:sahay/services/eligibility_engine.dart';
import 'package:sahay/services/privacy_service.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackendSchemeService Offline Fallback Tests', () {
    test('Offline fallback returns verified schemes when backend is unreachable', () async {
      final service = BackendSchemeService();
      final schemes = await service.getAllSchemes();

      expect(schemes.isNotEmpty, isTrue);
      expect(schemes.length, greaterThanOrEqualTo(6));
      expect(schemes.any((s) => s.schemeId.contains('pm-kisan') || s.name.contains('Kisan')), isTrue);
    });

    test('Single scheme lookup falls back to local catalogue', () async {
      final service = BackendSchemeService();
      final scheme = await service.getSchemeById('pm-kisan');

      expect(scheme, isNotNull);
      expect(scheme!.name, contains('Kisan'));
      expect(scheme.governmentLevel, equals(GovernmentLevel.central));
    });

    test('Local deterministic income estimation provides conservative range', () async {
      final service = BackendSchemeService();
      final req = const IncomeEstimationRequest(
        primarySource: 'farming',
        monthlyEstimatedIncome: 8000.0,
        householdEarners: 1,
        hasAgriculturalIncome: true,
        seasonalAgriculturalIncome: 24000.0,
      );

      final result = await service.estimateHouseholdIncome(req);
      expect(result.minAnnualIncome, greaterThan(0));
      expect(result.maxAnnualIncome, greaterThan(result.minAnnualIncome));
      expect(result.requiresOfficialVerification, isTrue);
      expect(result.assumptions.length, greaterThanOrEqualTo(2));
    });

    test('CSC locator fallback returns verified baseline centres', () async {
      final service = BackendSchemeService();
      final result = await service.searchCscCentres(state: 'Madhya Pradesh');

      expect(result.total, greaterThanOrEqualTo(1));
      expect(result.centres.any((c) => c.state == 'Madhya Pradesh'), isTrue);
      expect(result.centres.first.isVerified, isTrue);
    });
  });

  group('Shared-Device Privacy Tests (Mandatory Scenario 5)', () {
    test('Citizen A answers and results are wiped clean when session ends', () async {
      final userProfile = UserProfileProvider();
      final eligibility = EligibilityProvider(engine: const EligibilityEngine());
      final privacyService = PrivacyService();
      final schemeService = const SchemeDataService();

      // Step 1: Citizen A fills answers
      userProfile.setAnswers({
        'age': 32,
        'occupation': 'farmer',
        'landOwnership': 1.5,
        'state': 'Madhya Pradesh',
        'hasBankAccount': true,
        'annualIncome': 90000,
      });
      privacyService.setSessionAnswers(userProfile.answers);

      expect(userProfile.hasAnswers, isTrue);
      expect(userProfile.answeredCount, equals(6));
      expect(privacyService.hasPersonalData(), isTrue);

      // Step 2: Citizen A runs assessment
      final schemes = await schemeService.getAllSchemes();
      eligibility.evaluateAll(schemes, userProfile.answers);

      expect(eligibility.hasEvaluated, isTrue);
      expect(eligibility.results.isNotEmpty, isTrue);
      expect(eligibility.qualifyingCount, greaterThanOrEqualTo(1));

      // Step 3: Citizen A selects "End This Session"
      userProfile.clearAllAnswers();
      eligibility.clearResults();
      await privacyService.clearSessionData();

      // Step 4: Citizen B opens app
      expect(userProfile.hasAnswers, isFalse);
      expect(userProfile.answeredCount, equals(0));
      expect(userProfile.getAnswer('occupation'), isNull);
      expect(userProfile.getAnswer('annualIncome'), isNull);

      expect(eligibility.hasEvaluated, isFalse);
      expect(eligibility.results.isEmpty, isTrue);
      expect(eligibility.qualifyingCount, equals(0));

      expect(privacyService.hasPersonalData(), isFalse);
    });
  });
}
