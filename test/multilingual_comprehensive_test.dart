import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/l10n/strings_bn.dart';
import 'package:sahay/core/l10n/strings_en.dart';
import 'package:sahay/core/l10n/strings_gu.dart';
import 'package:sahay/core/l10n/strings_hi.dart';
import 'package:sahay/core/l10n/strings_kn.dart';
import 'package:sahay/core/l10n/strings_mr.dart';
import 'package:sahay/core/l10n/strings_or.dart';
import 'package:sahay/core/l10n/strings_ta.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/category_service.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/utils/auth_strings.dart';
import 'package:sahay/utils/indian_states.dart';
import 'package:sahay/utils/validators.dart';

void main() {
  group('Comprehensive Multilingual Test Across All 8 Languages', () {
    const supportedCodes = ['en', 'hi', 'ta', 'mr', 'bn', 'gu', 'kn', 'or'];

    test('All 8 supported languages are registered in SahayLocalizations', () {
      expect(SahayLocalizations.supportedLanguageCodes.length, 8);
      for (final code in supportedCodes) {
        expect(SahayLocalizations.supportedLanguageCodes.contains(code), isTrue,
            reason: 'Language code $code must be registered');
      }
    });

    test('All 8 translation dictionaries have exactly identical key sets', () {
      final dictionaries = <String, Map<String, String>>{
        'en': stringsEn,
        'hi': stringsHi,
        'ta': stringsTa,
        'mr': stringsMr,
        'bn': stringsBn,
        'gu': stringsGu,
        'kn': stringsKn,
        'or': stringsOr,
      };

      final enKeys = stringsEn.keys.toSet();
      expect(enKeys.length, greaterThanOrEqualTo(300),
          reason: 'English dictionary must contain at least 300 keys');

      for (final entry in dictionaries.entries) {
        final lang = entry.key;
        final dict = entry.value;

        // Symmetric keys check
        final diffFromEn = enKeys.difference(dict.keys.toSet());
        expect(diffFromEn, isEmpty,
            reason: 'Language $lang is missing keys: $diffFromEn');

        final diffExtra = dict.keys.toSet().difference(enKeys);
        expect(diffExtra, isEmpty,
            reason: 'Language $lang has extraneous keys: $diffExtra');

        // Non-empty string check
        for (final key in enKeys) {
          final val = dict[key];
          expect(val != null && val.trim().isNotEmpty, isTrue,
              reason: 'Key "$key" in language "$lang" is null or empty');
        }
      }
    });

    test('SahayLocalizations typed getters return valid localized values for each language', () {
      for (final code in supportedCodes) {
        final l10n = SahayLocalizations(Locale(code));
        expect(l10n.appName.isNotEmpty, isTrue);
        expect(l10n.welcomeTitle.isNotEmpty, isTrue);
        expect(l10n.continueAsGuest.isNotEmpty, isTrue);
        expect(l10n.myDocumentsVault.isNotEmpty, isTrue);
        expect(l10n.customDocumentNameHint.isNotEmpty, isTrue);
        expect(l10n.customDocumentNameRequired.isNotEmpty, isTrue);
        expect(l10n.edgeCasesPrecautions.isNotEmpty, isTrue);
        expect(l10n.criticalConditions.isNotEmpty, isTrue);
        expect(l10n.disqualificationReasons.isNotEmpty, isTrue);
        expect(l10n.downloadPdfChecklist.isNotEmpty, isTrue);
        expect(l10n.cscLocatorTitle.isNotEmpty, isTrue);
        expect(l10n.householdIncomeEstimation.isNotEmpty, isTrue);
        expect(l10n.endSessionConfirmationTitle.isNotEmpty, isTrue);
      }
    });

    test('IndianStates.getLocalizedName supports all 8 languages without falling back to empty', () {
      for (final state in IndianStates.states) {
        for (final code in supportedCodes) {
          final name = state.getLocalizedName(code);
          expect(name.isNotEmpty, isTrue,
              reason: 'State ${state.nameEnglish} missing name for lang $code');
          if (code != 'en') {
            expect(name != state.nameEnglish || state.nameHindi.isNotEmpty, isTrue);
          }
        }
      }
    });

    test('CategoryService.getCategoryName and getCategoryDescription support all 8 languages', () {
      final categories = CategoryService.allCategories.map((c) => c.categoryId).toList();

      for (final catId in categories) {
        for (final code in supportedCodes) {
          final name = CategoryService.getCategoryName(catId, code);
          final desc = CategoryService.getCategoryDescription(catId, lang: code);

          expect(name.isNotEmpty, isTrue,
              reason: 'Category $catId missing name for $code');
          expect(desc.isNotEmpty, isTrue,
              reason: 'Category $catId missing description for $code');
        }
      }
    });

    test('DocumentCatalogueService.getDisplayName supports all 8 languages', () {
      final allDocs = DocumentCatalogueService.getAllDocuments();
      expect(allDocs.length, greaterThanOrEqualTo(18));

      for (final doc in allDocs) {
        for (final code in supportedCodes) {
          final displayName = DocumentCatalogueService.getDisplayName(doc.documentType, code);
          expect(displayName.isNotEmpty, isTrue,
              reason: 'Doc ${doc.documentType} missing display name for $code');
        }
      }
    });

    test('SchemeModel.getLocalizedName supports all 8 languages', () {
      final dummyScheme = SchemeModel(
        schemeId: 'pm_kisan',
        name: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
        nameHindi: 'प्रधानमंत्री किसान सम्मान निधि (पीएम-किसान)',
        description: 'Direct income support of Rs 6000 per year',
        category: 'agriculture',
        benefits: 'Rs 6000 / year in 3 installments',
        eligibilityRules: const [],
        requiredDocuments: const [],
        applicationProcess: 'Online portal or CSC',
        ministry: 'Ministry of Agriculture',
        officialSourceUrl: 'https://pmkisan.gov.in',
        governmentLevel: GovernmentLevel.central,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      for (final code in supportedCodes) {
        final locName = dummyScheme.getLocalizedName(code);
        final locDesc = dummyScheme.getLocalizedDescription(code);
        final locBenefits = dummyScheme.getLocalizedBenefits(code);

        expect(locName.isNotEmpty, isTrue, reason: 'Failed for lang $code');
        expect(locDesc.isNotEmpty, isTrue, reason: 'Failed for lang $code');
        expect(locBenefits.isNotEmpty, isTrue, reason: 'Failed for lang $code');
      }
    });

    test('Validators error messages are localized for all 8 languages', () {
      for (final code in supportedCodes) {
        // Full Name validation
        expect(Validators.validateFullName('', code), isNotNull);
        expect(Validators.validateFullName('A', code), isNotNull);
        expect(Validators.validateFullName('Rajesh Kumar', code), isNull);

        // Mobile validation
        expect(Validators.validateMobile('', code), isNotNull);
        expect(Validators.validateMobile('12345', code), isNotNull);
        expect(Validators.validateMobile('9876543210', code), isNull);

        // Password validation
        expect(Validators.validatePassword('', code), isNotNull);
        expect(Validators.validatePassword('123', code), isNotNull);
        expect(Validators.validatePassword('ValidPass1!', code), isNull);

        // Confirm Password validation
        expect(Validators.validateConfirmPassword('pass1', 'pass2', code), isNotNull);
        expect(Validators.validateConfirmPassword('pass1', 'pass1', code), isNull);

        // Age validation
        expect(Validators.validateAge('', code), isNotNull);
        expect(Validators.validateAge('150', code), isNotNull);
        expect(Validators.validateAge('35', code), isNull);
      }
    });

    test('AuthStrings returns localized error messages for all 8 languages', () {
      const codes = [
        'invalid-email',
        'user-not-found',
        'wrong-password',
        'email-already-in-use',
        'weak-password',
        'network-request-failed',
        'session-expired',
      ];

      for (final errCode in codes) {
        for (final lang in supportedCodes) {
          final msg = AuthStrings.getMessage(errCode, lang);
          expect(msg.isNotEmpty, isTrue,
              reason: 'Auth error $errCode missing translation for $lang');
        }
      }
    });
  });
}
