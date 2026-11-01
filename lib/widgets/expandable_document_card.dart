import 'package:flutter/material.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/user_document_model.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/widgets/document_specimen_viewer.dart';

/// An expandable card for a required scheme document showing checklist status,
/// vault upload status badge, and comprehensive educational guidelines when expanded.
class ExpandableDocumentCard extends StatefulWidget {
  final String documentTitle;
  final bool isChecked;
  final ValueChanged<bool?> onChecked;
  final UserDocumentModel? uploadedDoc;
  final String language;
  final VoidCallback? onUploadPressed;
  final VoidCallback? onViewInVaultPressed;

  const ExpandableDocumentCard({
    super.key,
    required this.documentTitle,
    required this.isChecked,
    required this.onChecked,
    this.uploadedDoc,
    this.language = 'en',
    this.onUploadPressed,
    this.onViewInVaultPressed,
  });

  @override
  State<ExpandableDocumentCard> createState() => _ExpandableDocumentCardState();
}

class _ExpandableDocumentCardState extends State<ExpandableDocumentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final isHi = widget.language == 'hi';
    final canonicalId = DocumentCatalogueService.matchCanonicalId(widget.documentTitle);
    final docInfo = DocumentCatalogueService.getDocumentByType(canonicalId);
    final isUploaded = widget.uploadedDoc != null;

    final isGeneric = canonicalId == 'other_document' || docInfo == null;
    final String displayName = isGeneric
        ? widget.documentTitle
        : DocumentCatalogueService.getDisplayName(canonicalId, widget.language);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isChecked ? AppColors.paleSage.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isChecked
              ? AppColors.forestGreen
              : (_isExpanded ? AppColors.indianTeal : AppColors.border),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Always Visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Checklist Checkbox
                  Transform.scale(
                    scale: 1.05,
                    child: Checkbox(
                      value: widget.isChecked,
                      activeColor: AppColors.forestGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: widget.onChecked,
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Document Title & Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                            decoration: widget.isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Category Tag
                            if (docInfo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warmSand,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isHi ? docInfo.categoryHindi : docInfo.category,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepNavy.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),

                            // Vault Upload Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUploaded
                                    ? AppColors.paleSage
                                    : AppColors.warmSand.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isUploaded ? AppColors.forestGreen : AppColors.border,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUploaded
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_off_rounded,
                                    size: 11,
                                    color: isUploaded
                                        ? AppColors.forestGreen
                                        : AppColors.deepNavy.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isUploaded
                                        ? (isHi ? 'वॉल्ट में अपलोड है' : 'In Vault')
                                        : (isHi ? 'वॉल्ट में नहीं है' : 'Not in Vault'),
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isUploaded
                                          ? AppColors.forestGreen
                                          : AppColors.deepNavy.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Chevron
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.deepNavy,
                      size: 24,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Area
          if (_isExpanded && docInfo != null) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Clarification Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.softSaffron.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.softSaffron),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.deepNavy),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isHi
                                ? 'वॉल्ट स्थिति: दस्तावेज़ आपके निजी वॉल्ट में केवल संदर्भ हेतु सहेजा जाता है। यह सरकारी सत्यापन का विकल्प नहीं है।'
                                : 'Vault Note: Uploaded to personal vault for reference only. Does not replace official government verification.',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Purpose Section
                  _buildSectionHeader(
                    l10n.whyDocumentRequired,
                    Icons.help_outline_rounded,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHi ? docInfo.purposeHindi : docInfo.purpose,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Proves Section
                  _buildSectionHeader(
                    l10n.whatDoesItProve,
                    Icons.fact_check_outlined,
                  ),
                  const SizedBox(height: 6),
                  ...(isHi ? docInfo.provesInfoHindi : docInfo.provesInfo).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.indianTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.deepNavy,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Issuing Authority
                  _buildSectionHeader(
                    l10n.issuingAuthority,
                    Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHi ? docInfo.issuingAuthorityHindi : docInfo.issuingAuthority,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.indianTeal,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // How to Obtain
                  _buildSectionHeader(
                    l10n.howToObtain,
                    Icons.alt_route_rounded,
                  ),
                  const SizedBox(height: 6),
                  ...(isHi ? docInfo.howToObtainHindi : docInfo.howToObtain).map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.deepNavy,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.deepNavy.withValues(alpha: 0.85),
                                height: 1.35,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Important Checks (Pitfalls)
                  _buildSectionHeader(
                    l10n.importantChecks,
                    Icons.warning_amber_rounded,
                    headerColor: AppColors.mutedCoral,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mutedCoral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.mutedCoral.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: (isHi ? docInfo.importantChecksHindi : docInfo.importantChecks).map(
                        (check) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.mutedCoral),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  check,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.deepNavy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Specimen Mockup
                  DocumentSpecimenViewer(
                    documentInfo: docInfo,
                    language: widget.language,
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      if (isUploaded) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onViewInVaultPressed,
                            icon: const Icon(Icons.folder_shared_outlined, size: 16),
                            label: Text(l10n.viewInVault),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.indianTeal,
                              side: const BorderSide(color: AppColors.indianTeal),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onUploadPressed,
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: Text(l10n.replaceDocument),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indianTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onUploadPressed,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.uploadToVaultOptional,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.indianTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? headerColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: headerColor ?? AppColors.deepNavy),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: headerColor ?? AppColors.deepNavy,
            ),
          ),
        ),
      ],
    );
  }
}
