import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahay/core/config/app_config.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/l10n/strings_bn.dart';
import 'package:sahay/core/l10n/strings_en.dart';
import 'package:sahay/core/l10n/strings_gu.dart';
import 'package:sahay/core/l10n/strings_hi.dart';
import 'package:sahay/core/l10n/strings_kn.dart';
import 'package:sahay/core/l10n/strings_mr.dart';
import 'package:sahay/core/l10n/strings_or.dart';
import 'package:sahay/core/l10n/strings_ta.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  group('AppConfig Tests', () {
    test('Config contains expected values', () {
      expect(AppConfig.appName, equals('SAHAY'));
      expect(AppConfig.appVersion, equals('1.0.0'));
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.sessionTimeout, equals(const Duration(minutes: 30)));
      expect(AppConfig.supportedLanguageCodes.length, equals(8));
      expect(AppConfig.characterAssets.length, equals(8));
      expect(AppConfig.characterAssets['bn'], equals('assets/Bangali.jpeg'));
    });
  });

  group('AppColors Palette Tests', () {
    test('Matches required color hex codes', () {
      expect(AppColors.warmIvory, equals(const Color(0xFFF7F5EF)));
      expect(AppColors.deepNavy, equals(const Color(0xFF19344D)));
      expect(AppColors.indianTeal, equals(const Color(0xFF258C83)));
      expect(AppColors.softSaffron, equals(const Color(0xFFE3B66B)));
      expect(AppColors.paleSage, equals(const Color(0xFFE8F1EC)));
      expect(AppColors.warmSand, equals(const Color(0xFFF3E9DF)));
      expect(AppColors.forestGreen, equals(const Color(0xFF287A55)));
      expect(AppColors.mutedAmber, equals(const Color(0xFFB77924)));
      expect(AppColors.steelBlue, equals(const Color(0xFF426D9B)));
      expect(AppColors.mutedCoral, equals(const Color(0xFFB84C4C)));
      expect(AppColors.mutedPurple, equals(const Color(0xFF78649B)));
    });
  });

  group('Typography & Theme Tests', () {
    testWidgets('Text styles instantiate without errors', (tester) async {
      expect(AppTextStyles.heading1, isNotNull);
      expect(AppTextStyles.heading2, isNotNull);
      expect(AppTextStyles.heading3, isNotNull);
      expect(AppTextStyles.bodyLarge, isNotNull);
      expect(AppTextStyles.bodyMedium, isNotNull);
      expect(AppTextStyles.bodySmall, isNotNull);
      expect(AppTextStyles.buttonText, isNotNull);
      expect(AppTextStyles.caption, isNotNull);
      expect(AppTextStyles.label, isNotNull);
    });

    testWidgets('Theme builds properly for all supported languages', (tester) async {
      for (final lang in AppConfig.supportedLanguageCodes) {
        final theme = AppTheme.getTheme(lang);
        expect(theme.scaffoldBackgroundColor, equals(AppColors.warmIvory));
        expect(theme.colorScheme.primary, equals(AppColors.indianTeal));
        expect(theme.colorScheme.onSurface, equals(AppColors.deepNavy));
      }
    });
  });

  group('Localization Parity Tests', () {
    final enKeys = stringsEn.keys.toSet();

    final maps = <String, Map<String, String>>{
      'hi': stringsHi,
      'ta': stringsTa,
      'mr': stringsMr,
      'bn': stringsBn,
      'gu': stringsGu,
      'kn': stringsKn,
      'or': stringsOr,
    };

    test('All 8 string files have EXACTLY the same keys as English', () {
      expect(enKeys.isNotEmpty, isTrue);

      for (final entry in maps.entries) {
        final lang = entry.key;
        final map = entry.value;
        final keys = map.keys.toSet();

        final missing = enKeys.difference(keys);
        final extra = keys.difference(enKeys);

        expect(
          missing,
          isEmpty,
          reason: '$lang is missing keys: $missing',
        );
        expect(
          extra,
          isEmpty,
          reason: '$lang has unexpected extra keys: $extra',
        );
        expect(map.length, equals(stringsEn.length));
      }
    });

    test('SahayLocalizations getters return non-empty strings', () {
      for (final locale in SahayLocalizations.supportedLocales) {
        final l10n = SahayLocalizations(locale);

        expect(l10n.appName, isNotEmpty);
        expect(l10n.welcomeTitle, isNotEmpty);
        expect(l10n.welcomeSubtitle, isNotEmpty);
        expect(l10n.getStarted, isNotEmpty);
        expect(l10n.home, isNotEmpty);
        expect(l10n.search, isNotEmpty);
        expect(l10n.profile, isNotEmpty);
        expect(l10n.settings, isNotEmpty);
        expect(l10n.schemes, isNotEmpty);
        expect(l10n.eligibility, isNotEmpty);
        expect(l10n.agriculture, isNotEmpty);
        expect(l10n.health, isNotEmpty);
        expect(l10n.housing, isNotEmpty);
        expect(l10n.education, isNotEmpty);
        expect(l10n.women, isNotEmpty);
        expect(l10n.employment, isNotEmpty);
        expect(l10n.socialWelfare, isNotEmpty);
        expect(l10n.financial, isNotEmpty);
        expect(l10n.gender, isNotEmpty);
        expect(l10n.age, isNotEmpty);
        expect(l10n.state, isNotEmpty);
        expect(l10n.district, isNotEmpty);
        expect(l10n.occupation, isNotEmpty);
        expect(l10n.annualIncome, isNotEmpty);
        expect(l10n.aadhaar, isNotEmpty);
        expect(l10n.apply, isNotEmpty);
        expect(l10n.privacyTitle, isNotEmpty);
        expect(l10n.tapToSpeak, isNotEmpty);
        expect(l10n.networkError, isNotEmpty);
        expect(l10n.benefits, isNotEmpty);
        expect(l10n.youMayQualifyBecause, isNotEmpty);
      }
    });
  });
}
