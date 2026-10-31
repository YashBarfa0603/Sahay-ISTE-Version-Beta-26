import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/services/pdf_service.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentChecklistScreen extends StatefulWidget {
  final SchemeModel? singleScheme;

  const DocumentChecklistScreen({
    super.key,
    this.singleScheme,
  });

  @override
  State<DocumentChecklistScreen> createState() => _DocumentChecklistScreenState();
}

class _DocumentChecklistScreenState extends State<DocumentChecklistScreen> {
  final Map<String, Set<String>> _checkedDocsByScheme = {};
  final PdfService _pdfService = const PdfService();
  bool _isGeneratingPdf = false;

  Future<void> _downloadPdf(
    List<SchemeModel> schemes,
    Map<String, EligibilityResult> resultsMap,
    String userName,
    String language,
  ) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await _pdfService.generateChecklist(
        userName: userName,
        schemes: schemes,
        results: resultsMap,
        language: language,
      );

      if (!mounted) return;

      // Invoke real native Share/Save sheet (iOS Files/AirDrop/Android Share)
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'sahay_document_checklist.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language == 'hi'
                ? 'दस्तावेज चेकलिस्ट साझा/सहेजने के लिए तैयार है (${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)।'
                : 'Checklist PDF ready for saving/sharing (${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB).',
          ),
          backgroundColor: AppColors.forestGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share PDF: $e'),
          backgroundColor: AppColors.mutedCoral,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _printChecklist(
    List<SchemeModel> schemes,
    Map<String, EligibilityResult> resultsMap,
    String userName,
    String language,
  ) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await _pdfService.generateChecklist(
        userName: userName,
        schemes: schemes,
        results: resultsMap,
        language: language,
      );

      if (!mounted) return;

      // Invoke real native print dialog
      await Printing.layoutPdf(
        name: 'sahay_document_checklist.pdf',
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: AppColors.mutedCoral,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final eligibilityProvider = context.watch<EligibilityProvider>();
    final schemeProvider = context.watch<SchemeProvider>();
    final userProfile = context.watch<UserProfileProvider>();

    final userName = userProfile.getAnswer('fullName')?.toString() ?? 'Citizen';

    // Determine relevant schemes for the checklist
    final List<SchemeModel> targetSchemes;
    final Map<String, EligibilityResult> resultsMap = {};

    if (widget.singleScheme != null) {
      targetSchemes = [widget.singleScheme!];
      final res = eligibilityProvider.getResultForScheme(widget.singleScheme!.schemeId);
      resultsMap[widget.singleScheme!.schemeId] =
          res?.result ?? EligibilityResult.mayQualify;
    } else {
      final qualifyingAssessments = eligibilityProvider.qualifyingSchemes.isNotEmpty
          ? eligibilityProvider.qualifyingSchemes
          : (eligibilityProvider.needsInfoSchemes.isNotEmpty
              ? eligibilityProvider.needsInfoSchemes
              : eligibilityProvider.results);

      final schemeMap = {for (final s in schemeProvider.schemes) s.schemeId: s};
      final list = <SchemeModel>[];

      for (final a in qualifyingAssessments) {
        resultsMap[a.schemeId] = a.result;
        if (schemeMap.containsKey(a.schemeId)) {
          list.add(schemeMap[a.schemeId]!);
        }
      }

      if (list.isNotEmpty) {
        targetSchemes = list;
      } else {
        targetSchemes = schemeProvider.popularSchemes.isNotEmpty
            ? schemeProvider.popularSchemes
            : schemeProvider.schemes.take(5).toList();

        for (final s in targetSchemes) {
          resultsMap[s.schemeId] = EligibilityResult.mayQualify;
        }
      }
    }

    final screenTitle = currentLang == 'hi'
        ? 'आवश्यक दस्तावेज'
        : (l10n.requiredDocuments.isNotEmpty && l10n.requiredDocuments != 'requiredDocuments'
            ? l10n.requiredDocuments
            : 'Documents Needed');

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: screenTitle,
        showBackButton: true,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Text(
                'Verification & Application Checklist',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prepare the original certificates and self-attested copies below before submitting your government application.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.deepNavy.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons Row (Download PDF & Print)
              Row(
                children: [
                  // Download PDF Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPdf
                            ? null
                            : () => _downloadPdf(
                                  targetSchemes,
                                  resultsMap,
                                  userName,
                                  currentLang,
                                ),
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'Download PDF',
                          style: AppTextStyles.buttonText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indianTeal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Print Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingPdf
                            ? null
                            : () => _printChecklist(
                                  targetSchemes,
                                  resultsMap,
                                  userName,
                                  currentLang,
                                ),
                        icon: const Icon(Icons.print_rounded, color: AppColors.deepNavy, size: 20),
                        label: Text(
                          'Print',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.deepNavy, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Scheme-by-Scheme Document Sections
              if (targetSchemes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.paleSage,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('No schemes found for document generation.'),
                  ),
                )
              else
                ...targetSchemes.map((scheme) {
                  final schemeDocs = scheme.requiredDocuments.isNotEmpty
                      ? scheme.requiredDocuments
                      : ['Aadhaar Card (Linked with Mobile)', 'Active Bank Passbook', 'Passport-sized Photographs'];

                  _checkedDocsByScheme.putIfAbsent(scheme.schemeId, () => <String>{});
                  final checkedSet = _checkedDocsByScheme[scheme.schemeId]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.warmSand,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scheme Title and Ministry
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.indianTeal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: AppColors.indianTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scheme.name,
                                    style: AppTextStyles.heading3.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scheme.ministry,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.deepNavy.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Document Checkboxes
                        ...schemeDocs.map((doc) {
                          final isChecked = checkedSet.contains(doc);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    checkedSet.remove(doc);
                                  } else {
                                    checkedSet.add(doc);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  Icon(
                                    isChecked
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: isChecked
                                        ? AppColors.forestGreen
                                        : AppColors.deepNavy.withValues(alpha: 0.6),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      doc,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.deepNavy,
                                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Application Portal link
                        if (scheme.applicationUrl != null &&
                            scheme.applicationUrl!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.paleSage,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 18, color: AppColors.indianTeal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Official Application Portal',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.deepNavy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _launchUrl(scheme.applicationUrl!),
                                  child: Text(
                                    'Open Portal',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.indianTeal,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
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
                }),

              const SizedBox(height: 10),

              // Disclaimer Banner at Bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmSand,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.softSaffron,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.mutedAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Verification Disclaimer',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.disclaimerText.isNotEmpty && l10n.disclaimerText != 'disclaimerText'
                                ? l10n.disclaimerText
                                : 'Document requirements and eligibility rules are subject to official government circulars and district scrutiny. Please cross-verify with designated portal guidelines before applying.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.deepNavy.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
