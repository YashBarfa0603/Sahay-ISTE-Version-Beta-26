import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/models/user_model.dart';
import 'package:sahay/utils/auth_error_mapper.dart';
import 'package:sahay/utils/auth_strings.dart';
import 'package:sahay/utils/indian_states.dart';
import 'package:sahay/utils/profile_options.dart';
import 'package:sahay/utils/validators.dart';

void main() {
  group('UserModel API-neutral Model Tests', () {
    test('Serializes and deserializes UserModel correctly with new fields', () {
      final now = DateTime(2026, 10, 31, 10, 30);
      final user = UserModel(
        uid: 'user_123',
        fullName: 'Aarav Sharma',
        email: 'AARAV@EXAMPLE.COM',
        mobileNumber: '9876543210',
        age: 28,
        state: 'MP',
        district: 'Bhopal',
        occupation: 'farmer',
        preferredLanguage: 'hi',
        gender: 'male',
        residenceType: 'rural',
        profileComplete: true,
        authProvider: 'google',
        consentAcceptedAt: now,
        consentVersion: '1.0',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], equals('user_123'));
      expect(map['email'], equals('aarav@example.com')); // Lowercased
      expect(map['profileComplete'], isTrue);
      expect(map['authProvider'], equals('google'));

      final fromMapUser = UserModel.fromMap(map);
      expect(fromMapUser.uid, equals('user_123'));
      expect(fromMapUser.fullName, equals('Aarav Sharma'));
      expect(fromMapUser.email, equals('aarav@example.com'));
      expect(fromMapUser.age, equals(28));
      expect(fromMapUser.state, equals('MP'));
      expect(fromMapUser.profileComplete, isTrue);
      expect(fromMapUser.authProvider, equals('google'));
      expect(fromMapUser.consentVersion, equals('1.0'));
      expect(fromMapUser.consentAcceptedAt, equals(now));
    });

    test('Tolerates missing optional fields without crashing', () {
      final minimal = UserModel.fromMap({
        'uid': 'user_min',
        'fullName': 'Citizen',
        'email': 'citizen@example.com',
        'mobileNumber': '9876543210',
      });

      expect(minimal.uid, equals('user_min'));
      expect(minimal.profileComplete, isFalse);
      expect(minimal.authProvider, equals('email'));
      expect(minimal.age, isNull);
      expect(minimal.state, isNull);
    });

    test('copyWith updates specified fields only', () {
      final user = UserModel(
        uid: 'u1',
        fullName: 'Initial Name',
        email: 'u1@test.com',
        mobileNumber: '9876543210',
      );

      final updated = user.copyWith(
        fullName: 'Updated Name',
        age: 32,
        state: 'MH',
        profileComplete: true,
      );

      expect(updated.fullName, equals('Updated Name'));
      expect(updated.age, equals(32));
      expect(updated.state, equals('MH'));
      expect(updated.profileComplete, isTrue);
      expect(updated.uid, equals('u1'));
      expect(updated.email, equals('u1@test.com'));
    });
  });

  group('IndianStates Tests', () {
    test('Contains canonical catalogue state codes', () {
      final canonicalCodes = [
        'MP', 'MH', 'KA', 'WB', 'TN', 'UP', 'BR', 'JH', 'CG', 'AS', 'OD', 'RJ', 'GJ'
      ];
      for (final code in canonicalCodes) {
        expect(IndianStates.isValidCode(code), isTrue, reason: 'Missing code: $code');
      }
    });

    test('Returns localized English and Hindi names correctly', () {
      expect(IndianStates.getName('MP', 'en'), equals('Madhya Pradesh'));
      expect(IndianStates.getName('MP', 'hi'), equals('मध्य प्रदेश'));
      expect(IndianStates.getName('TN', 'en'), equals('Tamil Nadu'));
      expect(IndianStates.getName('TN', 'hi'), equals('तमिलनाडु'));
    });
  });

  group('ProfileOptions Canonical Occupations Tests', () {
    test('Contains exactly 13 canonical occupations from catalogue seed', () {
      expect(ProfileOptions.occupations.length, equals(13));
      final keys = ProfileOptions.occupations.map((o) => o.key).toSet();
      expect(keys.contains('farmer'), isTrue);
      expect(keys.contains('agricultural_worker'), isTrue);
      expect(keys.contains('unorganized_worker'), isTrue);
      expect(keys.contains('construction_worker'), isTrue);
      expect(keys.contains('street_vendor'), isTrue);
      expect(keys.contains('artisan_craftsperson'), isTrue);
      expect(keys.contains('student'), isTrue);
      expect(keys.contains('salaried_private'), isTrue);
      expect(keys.contains('government_employee'), isTrue);
      expect(keys.contains('self_employed_business'), isTrue);
      expect(keys.contains('homemaker'), isTrue);
      expect(keys.contains('unemployed'), isTrue);
      expect(keys.contains('retired'), isTrue);
    });

    test('Labels are available in English and Hindi', () {
      final farmerEn = ProfileOptions.getOccupationLabel('farmer', 'en');
      final farmerHi = ProfileOptions.getOccupationLabel('farmer', 'hi');
      expect(farmerEn, contains('Farmer'));
      expect(farmerHi, contains('किसान'));
    });
  });

  group('Validators Bilingual Tests', () {
    test('Validates email formatting', () {
      expect(Validators.validateEmail('user@test.com', 'en'), isNull);
      expect(Validators.validateEmail('invalid-email', 'en'), isNotNull);
      expect(Validators.validateEmail('', 'hi'), contains('ईमेल'));
    });

    test('Validates password rules (at least 8 chars with letter and number)', () {
      expect(Validators.validatePassword('Secret12', 'en'), isNull);
      expect(Validators.validatePassword('short1', 'en'), contains('at least 8'));
      expect(Validators.validatePassword('lettersnohyphen', 'en'), contains('one number'));
      expect(Validators.validatePassword('12345678', 'hi'), contains('अक्षर'));
    });

    test('Validates and sanitizes 10-digit Indian mobile numbers', () {
      expect(Validators.sanitizeMobile('+91 98765 43210'), equals('9876543210'));
      expect(Validators.sanitizeMobile('09876543210'), equals('9876543210'));
      expect(Validators.sanitizeMobile('9876543210'), equals('9876543210'));
      expect(Validators.sanitizeMobile('12345'), isNull); // Invalid
      expect(Validators.validateMobile('9876543210', 'en'), isNull);
      expect(Validators.validateMobile('12345', 'en'), contains('valid 10-digit'));
    });

    test('Validates age range between 0 and 120', () {
      expect(Validators.validateAge('25', 'en'), isNull);
      expect(Validators.validateAge('-5', 'en'), contains('between 0 and 120'));
      expect(Validators.validateAge('150', 'hi'), contains('0 से 120'));
    });
  });

  group('AuthStrings and Error Mapping Tests', () {
    test('Maps invalid credential to generic non-leaking message', () {
      final msgEn = AuthStrings.getMessage('invalid-credential', 'en');
      final msgHi = AuthStrings.getMessage('invalid-credential', 'hi');
      expect(msgEn, contains('email or password you entered is incorrect'));
      expect(msgHi, contains('ईमेल या पासवर्ड गलत है'));
    });

    test('Maps wrong-password and user-not-found to identical safe message', () {
      final wrongPass = AuthStrings.getMessage('wrong-password', 'en');
      final notFound = AuthStrings.getMessage('user-not-found', 'en');
      expect(wrongPass, equals(notFound));
    });

    test('AuthErrorMapper maps raw errors gracefully', () {
      final mapped = AuthErrorMapper.mapErrorToMessage('FirebaseAuthException: invalid-email', 'en');
      expect(mapped, contains('email address format is not valid'));
    });
  });
}

