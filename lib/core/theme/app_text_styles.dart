import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahay/core/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Styles
  static TextStyle get heading1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.deepNavy,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: AppColors.deepNavy,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.deepNavy,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.deepNavy,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.deepNavy,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.deepNavy,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.deepNavy,
        letterSpacing: 0.1,
      );

  // Script mapping
  static TextStyle applyLocaleFont(TextStyle style, [String languageCode = 'en']) {
    switch (languageCode.toLowerCase()) {
      case 'hi':
      case 'mr':
        return GoogleFonts.notoSansDevanagari(textStyle: style);
      case 'ta':
        return GoogleFonts.notoSansTamil(textStyle: style);
      case 'bn':
        return GoogleFonts.notoSansBengali(textStyle: style);
      case 'gu':
        return GoogleFonts.notoSansGujarati(textStyle: style);
      case 'kn':
        return GoogleFonts.notoSansKannada(textStyle: style);
      case 'or':
        return GoogleFonts.notoSansOriya(textStyle: style);
      case 'en':
      default:
        return GoogleFonts.poppins(textStyle: style);
    }
  }

  // Theme builder
  static TextTheme createTextTheme([String languageCode = 'en']) {
    final baseHeading1 = heading1;
    final baseHeading2 = heading2;
    final baseHeading3 = heading3;
    final baseBodyLarge = bodyLarge;
    final baseBodyMedium = bodyMedium;
    final baseBodySmall = bodySmall;
    final baseButtonText = buttonText;
    final baseCaption = caption;
    final baseLabel = label;

    return TextTheme(
      displayLarge: applyLocaleFont(baseHeading1.copyWith(fontSize: 34), languageCode),
      displayMedium: applyLocaleFont(baseHeading1.copyWith(fontSize: 30), languageCode),
      displaySmall: applyLocaleFont(baseHeading1, languageCode),
      headlineLarge: applyLocaleFont(baseHeading1, languageCode),
      headlineMedium: applyLocaleFont(baseHeading2, languageCode),
      headlineSmall: applyLocaleFont(baseHeading3, languageCode),
      titleLarge: applyLocaleFont(baseHeading2.copyWith(fontSize: 20), languageCode),
      titleMedium: applyLocaleFont(baseHeading3.copyWith(fontSize: 16), languageCode),
      titleSmall: applyLocaleFont(baseLabel.copyWith(fontSize: 14), languageCode),
      bodyLarge: applyLocaleFont(baseBodyLarge, languageCode),
      bodyMedium: applyLocaleFont(baseBodyMedium, languageCode),
      bodySmall: applyLocaleFont(baseBodySmall, languageCode),
      labelLarge: applyLocaleFont(baseButtonText, languageCode),
      labelMedium: applyLocaleFont(baseLabel, languageCode),
      labelSmall: applyLocaleFont(baseCaption, languageCode),
    );
  }

  // Accessors
  static TextStyle getHeading1(String languageCode) => applyLocaleFont(heading1, languageCode);
  static TextStyle getHeading2(String languageCode) => applyLocaleFont(heading2, languageCode);
  static TextStyle getHeading3(String languageCode) => applyLocaleFont(heading3, languageCode);
  static TextStyle getBodyLarge(String languageCode) => applyLocaleFont(bodyLarge, languageCode);
  static TextStyle getBodyMedium(String languageCode) => applyLocaleFont(bodyMedium, languageCode);
  static TextStyle getBodySmall(String languageCode) => applyLocaleFont(bodySmall, languageCode);
  static TextStyle getButtonText(String languageCode) => applyLocaleFont(buttonText, languageCode);
  static TextStyle getCaption(String languageCode) => applyLocaleFont(caption, languageCode);
  static TextStyle getLabel(String languageCode) => applyLocaleFont(label, languageCode);
}
