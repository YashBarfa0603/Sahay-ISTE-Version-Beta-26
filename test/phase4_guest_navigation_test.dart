import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/repositories/auth_repository.dart';
import 'package:sahay/services/auth_service.dart';
import 'package:sahay/services/user_service.dart';

class MockAuthService extends Fake implements AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() async {}
}

class MockUserService extends Fake implements UserService {}

void main() {
  group('Phase 4: Guest Navigation and Session Clearing Tests', () {
    late AuthProvider authProvider;
    late UserProfileProvider profileProvider;
    late UserDocumentProvider documentProvider;
    late ApplicationProvider appProvider;

    setUp(() {
      final repo = AuthRepository(
        authService: MockAuthService(),
        userService: MockUserService(),
      );
      authProvider = AuthProvider(authRepository: repo);
      profileProvider = UserProfileProvider();
      documentProvider = UserDocumentProvider();
      appProvider = ApplicationProvider();
    });

    test('Guest mode entry and exit flags', () {
      expect(authProvider.isGuest, isFalse);

      authProvider.enterGuestMode();
      expect(authProvider.isGuest, isTrue);

      authProvider.exitGuestMode();
      expect(authProvider.isGuest, isFalse);
    });

    test('UserDocumentProvider clear resets all cached documents and userId', () {
      documentProvider.clear();
      expect(documentProvider.documents, isEmpty);
      expect(documentProvider.currentUserId, isNull);
      expect(documentProvider.errorMessage, isNull);
      expect(documentProvider.isLoading, isFalse);
    });

    test('ApplicationProvider clearSession resets active session data', () {
      appProvider.clearSession();
      expect(appProvider.currentSession, isNull);
      expect(appProvider.portalPayload, isNull);
      expect(appProvider.readBackReport, isNull);
      expect(appProvider.errorMessage, isNull);
      expect(appProvider.isLoading, isFalse);
    });

    test('Session clearing wipes user profile answers completely', () {
      profileProvider.setAnswer('age', 45);
      profileProvider.setAnswer('occupation', 'Farmer');
      expect(profileProvider.answeredCount, 2);

      profileProvider.clearAllAnswers();
      expect(profileProvider.answeredCount, 0);
      expect(profileProvider.hasAnswers, isFalse);
      expect(profileProvider.getAnswer('age'), isNull);
    });

    test('Complete account switch flow: User A logs out, cache is wiped, User B is isolated', () async {
      // 1. User A active
      final userA = UserModel(
        uid: 'user_A',
        fullName: 'Citizen A',
        email: 'a@example.com',
        mobileNumber: '9999999991',
        age: 30,
        profileComplete: true,
      );
      profileProvider.populateFromUser(userA);
      expect(profileProvider.getAnswer('age'), 30);

      // 2. User A logs out: clear all caches
      profileProvider.clearAllAnswers();
      documentProvider.clear();
      appProvider.clearSession();
      await authProvider.signOut();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isGuest, isFalse);
      expect(profileProvider.hasAnswers, isFalse);
      expect(documentProvider.documents, isEmpty);

      // 3. Enter Guest mode smoothly
      authProvider.enterGuestMode();
      expect(authProvider.isGuest, isTrue);
      expect(authProvider.isAuthenticated, isFalse);
      expect(profileProvider.hasAnswers, isFalse);

      // 4. User B logs in
      authProvider.exitGuestMode();
      final userB = UserModel(
        uid: 'user_B',
        fullName: 'Citizen B',
        email: 'b@example.com',
        mobileNumber: '9999999992',
        age: 52,
        profileComplete: true,
      );
      profileProvider.populateFromUser(userB);

      // User B only sees their own data
      expect(profileProvider.getAnswer('age'), 52);
      expect(profileProvider.getAnswer('fullName'), 'Citizen B');
    });
  });
}
