import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/locale_provider.dart';

class LanguageToggle extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool showLabel;

  const LanguageToggle({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.showLabel = false,
  });

  // Bottom sheet
  static void showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.warmIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _LanguageSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final activeColor = iconColor ?? AppColors.indianTeal;

    if (showLabel) {
      return TextButton.icon(
        onPressed: () => showLanguageSheet(context),
        icon: Icon(Icons.language_rounded, size: iconSize, color: activeColor),
        label: Text(
          localeProvider.getNativeLanguageName(localeProvider.languageCode),
          style: AppTextStyles.label.copyWith(
            color: activeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.language_rounded,
        size: iconSize,
        color: activeColor,
      ),
      tooltip: 'Change Language / भाषा बदलें',
      padding: padding,
      onPressed: () => showLanguageSheet(context),
    );
  }
}

class _LanguageSelectionSheet extends StatelessWidget {
  const _LanguageSelectionSheet();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.languageCode;
    final supported = localeProvider.supportedLanguages;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header title with close icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    color: AppColors.indianTeal,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Language',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.deepNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'अपनी भाषा चुनें',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.deepNavy),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 24),

            // Language List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: supported.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final lang = supported[index];
                  final code = lang['code'] ?? 'en';
                  final nativeName = lang['nativeName'] ?? '';
                  final englishName = lang['name'] ?? '';
                  final assetPath = lang['asset'] ?? 'assets/English.jpeg';
                  final isSelected = code == currentCode;

                  return Material(
                    color: isSelected
                        ? AppColors.indianTeal.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        localeProvider.setLocale(Locale(code));
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.indianTeal
                                : AppColors.borderLight,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Character Illustration Avatar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: AppColors.warmSand,
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        nativeName.isNotEmpty
                                            ? nativeName[0]
                                            : code.toUpperCase(),
                                        style: AppTextStyles.heading3.copyWith(
                                          color: AppColors.indianTeal,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Language Names
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nativeName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.indianTeal
                                          : AppColors.deepNavy,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    englishName,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isSelected
                                          ? AppColors.indianTeal.withValues(alpha: 0.8)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Radio Indicator
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.indianTeal
                                      : AppColors.textMuted,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.indianTeal,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
