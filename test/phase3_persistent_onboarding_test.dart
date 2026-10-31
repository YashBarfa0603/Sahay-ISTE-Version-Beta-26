import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/services/auth_service.dart';
import 'package:sahay/services/user_service.dart';

// Fake auth service for unit testing
class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
}

class FakeUserService extends Fake implements UserService {}

void main() {
  group('Phase 3: Persistent User Onboarding Tests', () {
    test('UserModel initializes with onboardingCompleted and serializes properly', () {
      final user = UserModel(
        uid: 'user_001',
        fullName: 'Ramesh Patel',
        email: 'ramesh@example.com',
        mobileNumber: '9876543210',
        age: 38,
        state: 'Madhya Pradesh',
        district: 'Bhopal',
        occupation: 'Farmer',
        profileComplete: true,
        onboardingCompleted: true,
        onboardingCompletedAt: DateTime(2026, 11, 1),
      );

      final map = user.toMap();
      expect(map['profileComplete'], isTrue);
      expect(map['onboardingCompleted'], isTrue);
      expect(map['onboardingCompletedAt'], isNotNull);

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.profileComplete, isTrue);
      expect(reconstructed.onboardingCompleted, isTrue);
      expect(reconstructed.age, 38);
      expect(reconstructed.state, 'Madhya Pradesh');
    });

    test('UserModel backward compatibility: profileComplete true infers onboardingCompleted true', () {
      final legacyMap = {
        'uid': 'user_legacy',
        'fullName': 'Sita Devi',
        'email': 'sita@example.com',
        'mobileNumber': '9876543211',
        'profileComplete': true,
        // 'onboardingCompleted' absent in legacy record
      };

      final user = UserModel.fromMap(legacyMap);
      expect(user.profileComplete, isTrue);
      expect(user.onboardingCompleted, isTrue);
    });

    test('AuthProvider isProfileComplete reflects onboardingCompleted status accurately', () {
      final repo = AuthRepository(
        authService: FakeAuthService(),
        userService: FakeUserService(),
      );
      final provider = AuthProvider(authRepository: repo);

      expect(provider.isProfileComplete, isFalse);
    });

    test('UserProfileProvider populateFromUser populates demographic answers from UserModel', () {
      final profileProvider = UserProfileProvider();
      final user = UserModel(
        uid: 'user_101',
        fullName: 'Anita Sharma',
        email: 'anita@example.com',
        mobileNumber: '9123456789',
        age: 29,
        state: 'Rajasthan',
        district: 'Jaipur',
        occupation: 'Self-employed',
        gender: 'female',
        residenceType: 'rural',
        profileComplete: true,
        onboardingCompleted: true,
      );

      profileProvider.populateFromUser(user);

      expect(profileProvider.getAnswer('age'), 29);
      expect(profileProvider.getAnswer('state'), 'Rajasthan');
      expect(profileProvider.getAnswer('district'), 'Jaipur');
      expect(profileProvider.getAnswer('occupation'), 'Self-employed');
      expect(profileProvider.getAnswer('gender'), 'female');
      expect(profileProvider.getAnswer('residenceType'), 'rural');
      expect(profileProvider.hasAnswer('uid'), isFalse); // uid is kept separate
    });
  });
}
