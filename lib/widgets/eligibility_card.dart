import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/widgets/confidence_badge.dart';

class EligibilityCard extends StatelessWidget {
  final SchemeModel scheme;
  final EligibilityModel eligibility;
  final VoidCallback? onViewDetails;
  final VoidCallback? onTap;

  const EligibilityCard({
    super.key,
    required this.scheme,
    required this.eligibility,
    this.onViewDetails,
    this.onTap,
  });

  Color _getStatusColor(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return AppColors.forestGreen;
      case EligibilityResult.needsMoreInformation:
        return AppColors.steelBlue;
      case EligibilityResult.doesNotQualify:
        return AppColors.mutedCoral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider?>();
    final langCode = localeProvider?.languageCode ?? 'en';
    final l10n = SahayLocalizations.of(context);

    final statusColor = _getStatusColor(eligibility.result);

    // Title: use localized scheme name
    final displayName = scheme.getLocalizedName(langCode);

    final actionCallback = onViewDetails ?? onTap;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: actionCallback,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color-coded status strip on left side
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                ),

                // Card body content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Category tag & Status Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                scheme.category.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Confidence Badge
                            ConfidenceBadge(
                              result: eligibility.result,
                              fontSize: 11,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Scheme Title
                        Text(
                          displayName,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Ministry subtitle
                        Text(
                          scheme.ministry,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),

                        // Evidence & Condition Breakdown Summary
                        Builder(
                          builder: (context) {
                            final conditions = eligibility.conditionResults;
                            final passed = conditions.where((c) => c.status == ConditionStatus.passed).toList();
                            final failed = conditions.where((c) => c.status == ConditionStatus.failed).toList();
                            final pending = conditions.where((c) => c.status == ConditionStatus.pending).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Condition Status Summary Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        eligibility.result == EligibilityResult.mayQualify
                                            ? Icons.check_circle_rounded
                                            : eligibility.result == EligibilityResult.doesNotQualify
                                                ? Icons.cancel_rounded
                                                : Icons.help_outline_rounded,
                                        size: 15,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          eligibility.result == EligibilityResult.mayQualify
                                              ? (langCode == 'hi'
                                                  ? 'सभी ${passed.isNotEmpty ? "${passed.length} " : ""}आवश्यक शर्तें पूरी हैं'
                                                  : 'Meets all ${passed.isNotEmpty ? "${passed.length} " : ""}mandatory criteria')
                                              : eligibility.result == EligibilityResult.doesNotQualify
                                                  ? (langCode == 'hi'
                                                      ? '${failed.length} अनिवार्य शर्त${failed.length > 1 ? "ें" : ""} पूरी नहीं हुई'
                                                      : '${failed.length} mandatory criteria not satisfied')
                                                  : (langCode == 'hi'
                                                      ? 'पात्रता तय करने हेतु अतिरिक्त जानकारी आवश्यक'
                                                      : 'Additional information required for assessment'),
                                          style: AppTextStyles.caption.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Highlight first failed condition with specific difference
                                if (failed.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.mutedCoral.withValues(alpha: 0.25),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 13,
                                            color: AppColors.mutedCoral,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: RichText(
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.deepNavy,
                                                fontSize: 11.5,
                                                height: 1.3,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '${(langCode == 'hi' ? failed.first.labelHindi : null) ?? failed.first.label ?? failed.first.field}: ',
                                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                                TextSpan(
                                                  text: failed.first.differenceDescription ??
                                                      failed.first.explanation ??
                                                      'Does not meet required condition.',
                                                  style: const TextStyle(color: AppColors.mutedCoral),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Missing information indicator
                                if (eligibility.result == EligibilityResult.needsMoreInformation &&
                                    (eligibility.missingInformation.isNotEmpty || pending.isNotEmpty)) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.steelBlue.withValues(alpha: 0.25),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.help_outline_rounded,
                                          size: 13,
                                          color: AppColors.steelBlue,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            langCode == 'hi'
                                                ? 'आवश्यक: ${(eligibility.missingInformation.isNotEmpty ? eligibility.missingInformation : pending.map((p) => p.labelHindi ?? p.label ?? p.field)).join(", ")}'
                                                : 'Missing: ${(eligibility.missingInformation.isNotEmpty ? eligibility.missingInformation : pending.map((p) => p.label ?? p.field)).join(", ")}',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.steelBlue,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // General Explanation container
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.border.withValues(alpha: 0.4),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    eligibility.explanation,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.deepNavy,
                                      height: 1.35,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Bottom Actions: Gov Level & View Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Gov Level Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.governmentLevel == GovernmentLevel.central
                                    ? AppColors.steelBlue.withValues(alpha: 0.12)
                                    : AppColors.mutedPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scheme.governmentLevel == GovernmentLevel.central
                                    ? (langCode == 'hi' ? 'केंद्रीय' : 'Central')
                                    : (langCode == 'hi' ? 'राज्य' : 'State'),
                                style: AppTextStyles.caption.copyWith(
                                  color: scheme.governmentLevel == GovernmentLevel.central
                                      ? AppColors.steelBlue
                                      : AppColors.mutedPurple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            // "View Details" action button
                            InkWell(
                              onTap: actionCallback,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.viewDetails,
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.indianTeal,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 15,
                                      color: AppColors.indianTeal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
