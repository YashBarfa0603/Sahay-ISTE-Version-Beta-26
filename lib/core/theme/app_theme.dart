import 'package:flutter/material.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => getTheme('en');

  // Theme builder
  static ThemeData getTheme([String languageCode = 'en']) {
    final textTheme = AppTextStyles.createTextTheme(languageCode);
    final heading2Style = AppTextStyles.getHeading2(languageCode);
    final buttonTextStyle = AppTextStyles.getButtonText(languageCode);
    final labelStyle = AppTextStyles.getLabel(languageCode);
    final captionStyle = AppTextStyles.getCaption(languageCode);
    final bodyMediumStyle = AppTextStyles.getBodyMedium(languageCode);

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.indianTeal,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleSage,
      onPrimaryContainer: AppColors.deepNavy,
      secondary: AppColors.softSaffron,
      onSecondary: AppColors.deepNavy,
      secondaryContainer: AppColors.warmSand,
      onSecondaryContainer: AppColors.deepNavy,
      tertiary: AppColors.steelBlue,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.paleSage,
      onTertiaryContainer: AppColors.deepNavy,
      error: AppColors.mutedCoral,
      onError: Colors.white,
      errorContainer: const Color(0xFFF9DCDC),
      onErrorContainer: AppColors.mutedCoral,
      surface: Colors.white,
      onSurface: AppColors.deepNavy,
      surfaceContainerHighest: AppColors.warmSand,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
      shadow: AppColors.deepNavy.withValues(alpha: 0.08),
      inverseSurface: AppColors.deepNavy,
      onInverseSurface: AppColors.warmIvory,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmIvory,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmIvory,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.deepNavy),
        actionsIconTheme: const IconThemeData(color: AppColors.deepNavy),
        titleTextStyle: heading2Style.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indianTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderLight,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.indianTeal,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.indianTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonTextStyle.copyWith(color: AppColors.indianTeal),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.indianTeal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: labelStyle.copyWith(
            color: AppColors.indianTeal,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: AppColors.deepNavy.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.indianTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedCoral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedCoral, width: 2),
        ),
        hintStyle: bodyMediumStyle.copyWith(color: AppColors.textMuted),
        labelStyle: bodyMediumStyle.copyWith(color: AppColors.deepNavy),
        floatingLabelStyle: labelStyle.copyWith(color: AppColors.indianTeal),
      ),

      // BottomNav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.indianTeal,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: captionStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.indianTeal,
        ),
        unselectedLabelStyle: captionStyle,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.paleSage,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return captionStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.indianTeal,
            );
          }
          return captionStyle.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.indianTeal);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: heading2Style,
        contentTextStyle: bodyMediumStyle,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.warmSand,
        selectedColor: AppColors.paleSage,
        disabledColor: AppColors.borderLight,
        secondarySelectedColor: AppColors.paleSage,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: captionStyle.copyWith(
          color: AppColors.deepNavy,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: captionStyle.copyWith(
          color: AppColors.indianTeal,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.indianTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: bodyMediumStyle.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
