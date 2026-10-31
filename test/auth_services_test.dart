import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/services/auth_service.dart';
import 'package:sahay/services/user_service.dart';
import 'package:sahay/utils/auth_error_mapper.dart';

// Test doubles
class MockUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? phoneNumber;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
  });
}

class FakeAuthService extends Fake implements AuthService {
  User? userToReturn;
  bool throwWrongPassword = false;
  bool throwEmailAlreadyInUse = false;
  bool cancelGoogle = false;

  @override
  Stream<User?> get authStateChanges => Stream.value(userToReturn);

  @override
  User? get currentUser => userToReturn;

  @override
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwEmailAlreadyInUse) {
      throw const AuthFailure(code: 'email-already-in-use', messageKey: 'email-already-in-use');
    }
    return userToReturn;
  }

  @override
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwWrongPassword) {
      throw const AuthFailure(code: 'wrong-password', messageKey: 'wrong-password');
    }
    return userToReturn;
  }

  @override
  Future<User?> signInWithGoogle() async {
    if (cancelGoogle) {
      return null;
    }
    return userToReturn;
  }
}

class FakeUserService extends Fake implements UserService {
  final Map<String, UserModel> profiles = {};
  int createProfileCallCount = 0;
  bool throwDatabaseError = false;

  @override
  Future<UserModel?> getProfile(String uid) async {
    if (throwDatabaseError) {
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
    return profiles[uid];
  }

  @override
  Future<void> createProfile(UserModel user) async {
    createProfileCallCount++;
    if (throwDatabaseError) {
      throw const AuthFailure(code: 'database-error', messageKey: 'database-error');
    }
    if (!profiles.containsKey(user.uid)) {
      profiles[user.uid] = user;
    }
  }

  @override
  Stream<UserModel?> profileStream(String uid) {
    return Stream.value(profiles[uid]);
  }
}

void main() {
  group('Phase B - Auth & User Services & Repository Tests', () {
    test('1. fromMap handles nulls, missing fields, and Firestore Timestamp', () {
      final now = DateTime(2026, 10, 31, 8, 0, 0);
      final timestamp = Timestamp.fromDate(now);

      final mapWithTimestamp = {
        'uid': 'test_uid_123',
        'fullName': 'Aarav Sharma',
        'email': 'AARAV@EXAMPLE.COM',
        'mobileNumber': '9876543210',
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'consentAcceptedAt': timestamp,
        // age, state, district, occupation missing/null
      };

      final user = UserModel.fromMap(mapWithTimestamp);

      expect(user.uid, 'test_uid_123');
      expect(user.fullName, 'Aarav Sharma');
      expect(user.email, 'aarav@example.com'); // normalized
      expect(user.age, isNull);
      expect(user.state, isNull);
      expect(user.district, isNull);
      expect(user.occupation, isNull);
      expect(user.profileComplete, isFalse);
      expect(user.authProvider, 'email');
      expect(user.createdAt, now);
      expect(user.updatedAt, now);
      expect(user.consentAcceptedAt, now);

      // Null or empty map
      final emptyUser = UserModel.fromMap({});
      expect(emptyUser.uid, '');
      expect(emptyUser.email, '');
      expect(emptyUser.profileComplete, isFalse);
      expect(emptyUser.createdAt, isNull);
    });

    test('2. signing up without consent throws AuthFailure(consent-required)', () async {
      final fakeAuth = FakeAuthService();
      final fakeUser = FakeUserService();
      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      expect(
        () => repository.signUp(
          email: 'test@example.com',
          password: 'Password123!',
          fullName: 'Test User',
          mobileNumber: '9876543210',
          consentAccepted: false,
        ),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'consent-required'),
        ),
      );
      expect(fakeUser.createProfileCallCount, 0);
    });

    test('3. wrong password throws mapped AuthFailure', () async {
      final fakeAuth = FakeAuthService()..throwWrongPassword = true;
      final fakeUser = FakeUserService();
      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      expect(
        () => repository.signIn(
          email: 'test@example.com',
          password: 'WrongPassword!',
        ),
        throwsA(
          isA<AuthFailure>().having((e) => e.code, 'code', 'wrong-password'),
        ),
      );
    });

    test('4. cancelling Google sign-in does not throw and returns null quietly', () async {
      final fakeAuth = FakeAuthService()..cancelGoogle = true;
      final fakeUser = FakeUserService();
      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      final result = await repository.signInWithGoogle();
      expect(result, isNull);
      expect(fakeUser.createProfileCallCount, 0);
    });

    test('5. first-time Google sign-in creates stub profile and marks profileComplete: false', () async {
      final mockGoogleUser = MockUser(
        uid: 'google_uid_001',
        email: 'googleuser@example.com',
        displayName: 'Google Tester',
      );
      final fakeAuth = FakeAuthService()..userToReturn = mockGoogleUser;
      final fakeUser = FakeUserService();
      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      final profile = await repository.signInWithGoogle();

      expect(profile, isNotNull);
      expect(profile!.uid, 'google_uid_001');
      expect(profile.email, 'googleuser@example.com');
      expect(profile.fullName, 'Google Tester');
      expect(profile.authProvider, 'google');
      expect(profile.profileComplete, isFalse);
      expect(fakeUser.createProfileCallCount, 1);
      expect(fakeUser.profiles['google_uid_001']?.profileComplete, isFalse);
    });

    test('6. returning Google sign-in preserves profile and does not overwrite existing data', () async {
      final mockGoogleUser = MockUser(
        uid: 'google_uid_002',
        email: 'returning@example.com',
        displayName: 'Returning User',
      );

      final existingProfile = UserModel(
        uid: 'google_uid_002',
        fullName: 'Custom Full Name',
        email: 'returning@example.com',
        mobileNumber: '9123456780',
        age: 35,
        state: 'MP',
        district: 'Bhopal',
        occupation: 'farmer',
        preferredLanguage: 'hi',
        profileComplete: true,
        authProvider: 'google',
      );

      final fakeAuth = FakeAuthService()..userToReturn = mockGoogleUser;
      final fakeUser = FakeUserService();
      fakeUser.profiles['google_uid_002'] = existingProfile;

      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      final profile = await repository.signInWithGoogle();

      expect(profile, isNotNull);
      expect(profile!.uid, 'google_uid_002');
      expect(profile.fullName, 'Custom Full Name');
      expect(profile.occupation, 'farmer');
      expect(profile.profileComplete, isTrue);
      expect(fakeUser.createProfileCallCount, 0); // Did not recreate or overwrite
    });

    test('7. email sign-in auto-recovers stub profile when user exists in Auth but has no Firestore profile', () async {
      final mockAuthUser = MockUser(
        uid: 'recovered_uid_101',
        email: 'missing_profile@example.com',
        displayName: 'Recovered Citizen',
      );

      final fakeAuth = FakeAuthService()..userToReturn = mockAuthUser;
      final fakeUser = FakeUserService(); // Empty profiles

      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      final profile = await repository.signIn(
        email: 'missing_profile@example.com',
        password: 'Password123',
      );

      expect(profile, isNotNull);
      expect(profile!.uid, 'recovered_uid_101');
      expect(profile.email, 'missing_profile@example.com');
      expect(profile.fullName, 'Recovered Citizen');
      expect(profile.authProvider, 'email');
      expect(fakeUser.createProfileCallCount, 1);
      expect(fakeUser.profiles['recovered_uid_101'], isNotNull);
    });

    test('8. email sign-up auto-recovers when email-already-in-use occurs and profile is missing', () async {
      final mockExistingUser = MockUser(
        uid: 'orphan_auth_user_202',
        email: 'orphan@example.com',
        displayName: 'Orphan User',
      );

      final fakeAuth = FakeAuthService()
        ..throwEmailAlreadyInUse = true
        ..userToReturn = mockExistingUser;
      final fakeUser = FakeUserService(); // Profile does not exist in Firestore

      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      final profile = await repository.signUp(
        email: 'ORPHAN@EXAMPLE.COM',
        password: 'Password123',
        fullName: 'Orphan Resolved',
        mobileNumber: '9876543210',
        consentAccepted: true,
      );

      expect(profile, isNotNull);
      expect(profile.uid, 'orphan_auth_user_202');
      expect(profile.email, 'orphan@example.com');
      expect(profile.fullName, 'Orphan Resolved');
      expect(fakeUser.profiles['orphan_auth_user_202'], isNotNull);
    });

    test('9. email sign-up tolerates Firestore creation failure without stranding user', () async {
      final mockNewUser = MockUser(
        uid: 'new_user_offline',
        email: 'offline@example.com',
      );

      final fakeAuth = FakeAuthService()..userToReturn = mockNewUser;
      final fakeUser = FakeUserService()..throwDatabaseError = true;

      final repository = AuthRepository(
        authService: fakeAuth,
        userService: fakeUser,
      );

      // Should not throw, should return user in memory
      final profile = await repository.signUp(
        email: 'offline@example.com',
        password: 'Password123',
        fullName: 'Offline User',
        mobileNumber: '9876543210',
        consentAccepted: true,
      );

      expect(profile, isNotNull);
      expect(profile.uid, 'new_user_offline');
      expect(profile.email, 'offline@example.com');
      expect(profile.fullName, 'Offline User');
    });
  });
}

