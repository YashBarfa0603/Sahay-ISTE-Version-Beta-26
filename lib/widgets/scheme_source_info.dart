import 'package:flutter/material.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeSourceInfo extends StatelessWidget {
  final SchemeModel scheme;
  final EdgeInsetsGeometry padding;

  const SchemeSourceInfo({
    super.key,
    required this.scheme,
    this.padding = const EdgeInsets.all(16.0),
  });

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Staleness
  Color _getStalenessColor(DateTime? lastVerified) {
    if (lastVerified == null) return AppColors.mutedCoral;

    final daysDifference = DateTime.now().difference(lastVerified).inDays;
    if (daysDifference <= 90) {
      return AppColors.forestGreen;
    } else if (daysDifference <= 180) {
      return AppColors.mutedAmber;
    } else {
      return AppColors.mutedCoral;
    }
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }

  String _getStalenessText(DateTime? lastVerified, BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    if (lastVerified == null) {
      return 'Verification pending';
    }

    final formattedDate = _formatDate(lastVerified);
    final days = DateTime.now().difference(lastVerified).inDays;

    if (days <= 90) {
      return '${l10n.lastVerified}: $formattedDate (Verified)';
    } else if (days <= 180) {
      return '${l10n.lastVerified}: $formattedDate (Review due)';
    } else {
      return '${l10n.lastVerified}: $formattedDate (Stale)';
    }
  }

  Future<void> _openOfficialUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final dotColor = _getStalenessColor(scheme.lastVerified);
    final stalenessLabel = _getStalenessText(scheme.lastVerified, context);
    final isPending = scheme.verificationStatus == VerificationStatus.pending ||
        scheme.status == SchemeStatus.underVerification;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paleSage,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Source Title & Verification Dot
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 18,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.officialSource,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              // Staleness Dot & Label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stalenessLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: dotColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Source Authority Name
          if (scheme.sourceName != null && scheme.sourceName!.isNotEmpty) ...[
            Text(
              scheme.sourceName!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Official URL Link
          if (scheme.officialSourceUrl.isNotEmpty) ...[
            InkWell(
              onTap: () => _openOfficialUrl(scheme.officialSourceUrl),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: AppColors.indianTeal,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        scheme.officialSourceUrl,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.indianTeal,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Pending verification disclaimer banner
          if (isPending) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softSaffron.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.mutedAmber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.mutedAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice: This scheme is currently undergoing administrative verification. Please cross-verify rules on the official government website.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepNavy,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
