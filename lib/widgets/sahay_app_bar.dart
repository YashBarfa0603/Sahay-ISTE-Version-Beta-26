import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/widgets/language_toggle.dart';

class SahayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool isTransparent;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final bool showLanguageToggle;
  final bool showClearData;
  final VoidCallback? onClearData;
  final List<Widget>? extraActions;
  final double elevation;

  const SahayAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.isTransparent = false,
    this.showBackButton,
    this.onBack,
    this.showLanguageToggle = true,
    this.showClearData = false,
    this.onClearData,
    this.extraActions,
    this.elevation = 0.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _confirmClearData(BuildContext context) {
    final l10n = SahayLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.mutedAmber,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.clearData,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.deepNavy,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.clearDataConfirm,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.deepNavy,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onClearData != null) {
                onClearData!();
              } else {
                // Clear session providers
                final profileProvider =
                    Provider.of<UserProfileProvider?>(context, listen: false);
                final eligibilityProvider =
                    Provider.of<EligibilityProvider?>(context, listen: false);

                profileProvider?.clearAllAnswers();
                eligibilityProvider?.clearResults();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.dataCleared),
                    backgroundColor: AppColors.forestGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.clearData,
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;

    final Color backgroundColor =
        isTransparent ? Colors.transparent : AppColors.deepNavy;
    final Color foregroundColor =
        isTransparent ? AppColors.deepNavy : Colors.white;

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      centerTitle: true,
      automaticallyImplyLeading: false,

      // Left Section: Back Button or SAHAY Brand Logo
      leading: shouldShowBack
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: foregroundColor,
                size: 24,
              ),
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SAHAY',
                  style: AppTextStyles.heading3.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
      leadingWidth: shouldShowBack ? 56 : 90,

      // Center Title
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.heading3.copyWith(
                    color: foregroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              : null),

      // Right Section: Clear Data & Language Toggle Actions
      actions: [
        ...?extraActions,

        // Optional Clear Session Data Action (Privacy protection)
        if (showClearData)
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: isTransparent ? AppColors.mutedCoral : AppColors.softSaffron,
              size: 24,
            ),
            tooltip: 'Clear session data',
            onPressed: () => _confirmClearData(context),
          ),

        // Language Toggle Globe Button
        if (showLanguageToggle)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: LanguageToggle(
              iconColor: isTransparent ? AppColors.deepNavy : Colors.white,
            ),
          ),
      ],
    );
  }
}
