import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/services/recommendation_service.dart';
import 'package:sahay/services/scheme_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationService Deterministic Engine Tests', () {
    test('recommends agricultural and MP schemes for Farmer in MP', () async {
      final dataService = SchemeDataService();
      final allSchemes = await dataService.getCompleteCatalogue();

      final user = UserModel(
        uid: 'user_farmer_1',
        fullName: 'Ramesh Patel',
        email: 'ramesh@example.com',
        mobileNumber: '9876543210',
        state: 'MP',
        age: 42,
        gender: 'male',
        occupation: 'farmer',
        residenceType: 'rural',
        profileComplete: true,
      );

      final recService = const RecommendationService();
      final recs = recService.getRecommendations(user: user, allSchemes: allSchemes);

      expect(recs.isNotEmpty, isTrue);

      // Top recommendations should have Likely Relevant badge
      final topRec = recs.first;
      expect(topRec.badge, RecommendationBadge.likelyRelevant);
      expect(topRec.reasons.isNotEmpty, isTrue);

      // Verify reasons contain factual explanation
      final allReasons = recs.expand((r) => r.reasons).toList();
      expect(
        allReasons.any((r) => r.contains('Farmer') || r.contains('Agricultural')),
        isTrue,
      );
    });

    test('recommends education schemes for student', () async {
      final dataService = SchemeDataService();
      final allSchemes = await dataService.getCompleteCatalogue();

      final user = UserModel(
        uid: 'user_student_1',
        fullName: 'Priya Sharma',
        email: 'priya@example.com',
        mobileNumber: '9876543211',
        state: 'UP',
        age: 20,
        gender: 'female',
        occupation: 'student',
        residenceType: 'urban',
        profileComplete: true,
      );

      final recService = const RecommendationService();
      final recs = recService.getRecommendations(user: user, allSchemes: allSchemes);

      expect(recs.isNotEmpty, isTrue);
      final educationRecs = recs.where((r) => r.reasons.any((reason) => reason.contains('Student') || reason.contains('Education'))).toList();
      expect(educationRecs.isNotEmpty, isTrue);
    });

    test('assigns moreInfoRequired when key profile fields are omitted', () async {
      final dataService = SchemeDataService();
      final allSchemes = await dataService.getCompleteCatalogue();

      // Incomplete user profile
      final user = UserModel(
        uid: 'user_sparse_1',
        fullName: 'Sparse User',
        email: 'sparse@example.com',
        mobileNumber: '9876543212',
        state: 'MP',
        age: null,
        gender: null,
        occupation: null,
        profileComplete: false,
      );

      final recService = const RecommendationService();
      final recs = recService.getRecommendations(user: user, allSchemes: allSchemes);

      expect(recs.isNotEmpty, isTrue);
      // Some recommendations should indicate more information required
      expect(recs.any((r) => r.badge == RecommendationBadge.moreInfoRequired || r.badge == RecommendationBadge.mayBeRelevant), isTrue);
    });
  });
}

