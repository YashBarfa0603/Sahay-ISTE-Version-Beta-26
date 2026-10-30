import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/providers/locale_provider.dart';

class ConfidenceBadge extends StatelessWidget {
  final EligibilityResult result;
  final String? customLabel;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ConfidenceBadge({
    super.key,
    required this.result,
    this.customLabel,
    this.showIcon = true,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider?>();
    final langCode = localeProvider?.languageCode ?? 'en';

    final Color backgroundColor;
    final IconData iconData;
    final String labelText;

    switch (result) {
      case EligibilityResult.mayQualify:
        backgroundColor = AppColors.forestGreen;
        iconData = Icons.check_circle_rounded;
        labelText = customLabel ?? (langCode == 'hi' ? 'योग्य हो सकते हैं' : 'May Qualify');
        break;
      case EligibilityResult.needsMoreInformation:
        backgroundColor = AppColors.steelBlue;
        iconData = Icons.help_outline_rounded;
        labelText = customLabel ?? (langCode == 'hi' ? 'अधिक जानकारी आवश्यक' : 'More Info Needed');
        break;
      case EligibilityResult.doesNotQualify:
        backgroundColor = AppColors.mutedCoral;
        iconData = Icons.cancel_rounded;
        labelText = customLabel ?? (langCode == 'hi' ? 'पात्र नहीं' : 'Not Eligible');
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              iconData,
              size: fontSize + 2,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            labelText,
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
