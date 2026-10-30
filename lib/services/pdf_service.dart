import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';

/// Service to generate downloadable, printable document checklist PDFs for eligible schemes.
class PdfService {
  const PdfService();

  // SAHAY Palette Constants
  static const PdfColor colorWarmIvory = PdfColor.fromInt(0xFFF7F5EF);
  static const PdfColor colorDeepNavy = PdfColor.fromInt(0xFF19344D);
  static const PdfColor colorIndianTeal = PdfColor.fromInt(0xFF258C83);
  static const PdfColor colorSoftSaffron = PdfColor.fromInt(0xFFE3B66B);
  static const PdfColor colorPaleSage = PdfColor.fromInt(0xFFE8F1EC);
  static const PdfColor colorWarmSand = PdfColor.fromInt(0xFFF3E9DF);
  static const PdfColor colorForestGreen = PdfColor.fromInt(0xFF287A55);
  static const PdfColor colorMutedAmber = PdfColor.fromInt(0xFFB77924);
  static const PdfColor colorMutedCoral = PdfColor.fromInt(0xFFB84C4C);
  static const PdfColor colorBorderGray = PdfColor.fromInt(0xFFD6D1C5);

  /// Generate a document checklist PDF for eligible schemes.
  Future<Uint8List> generateChecklist({
    required String userName,
    required List<SchemeModel> schemes,
    required Map<String, EligibilityResult> results,
    required String language,
  }) async {
    final pdf = pw.Document(
      title: 'SAHAY - Government Scheme Document Checklist',
      author: 'SAHAY Eligibility Engine',
    );

    // Filter qualifying schemes (mayQualify or needsMoreInformation)
    final qualifyingSchemes = schemes.where((s) {
      final res = results[s.schemeId];
      return res == EligibilityResult.mayQualify ||
          res == EligibilityResult.needsMoreInformation;
    }).toList();

    // Sort: mayQualify first, then needsMoreInformation
    qualifyingSchemes.sort((a, b) {
      final resA = results[a.schemeId] ?? EligibilityResult.needsMoreInformation;
      final resB = results[b.schemeId] ?? EligibilityResult.needsMoreInformation;
      if (resA != resB) {
        return resA == EligibilityResult.mayQualify ? -1 : 1;
      }
      return (a.popularityRank).compareTo(b.popularityRank);
    });

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')} ${_monthName(now.month)} ${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header: (pw.Context context) => _buildHeader(formattedDate, userName),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) {
          if (qualifyingSchemes.isEmpty) {
            return [
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: colorPaleSage,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: colorIndianTeal, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'No Currently Qualifying Schemes Found',
                      style: pw.TextStyle(
                        color: colorDeepNavy,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Based on the preliminary details provided, no specific central or state scheme matches were confirmed. You may update your profile answers in SAHAY to reassess new or updated welfare opportunities.',
                      style: const pw.TextStyle(
                        color: colorDeepNavy,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          }

          return [
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: colorPaleSage,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: colorIndianTeal, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Applicant Name: $userName',
                        style: pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Total Relevant Schemes Identified: ${qualifyingSchemes.length}',
                        style: const pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: const pw.BoxDecoration(
                      color: colorIndianTeal,
                      borderRadius:
                          pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'OFFICIAL CHECKLIST',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            ...qualifyingSchemes.map((scheme) {
              final result = results[scheme.schemeId] ??
                  EligibilityResult.needsMoreInformation;
              return _buildSchemeSection(scheme, result);
            }),
            pw.SizedBox(height: 16),
            _buildDisclaimerBox(),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildHeader(String date, String userName) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'SAHAY',
                      style: pw.TextStyle(
                        color: colorIndianTeal,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '|  सहाय',
                      style: pw.TextStyle(
                        color: colorSoftSaffron,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Citizen Scheme Eligibility & Application Assistant',
                  style: const pw.TextStyle(
                    color: colorDeepNavy,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated: $date',
                  style: const pw.TextStyle(
                    color: colorDeepNavy,
                    fontSize: 8.5,
                  ),
                ),
                pw.Text(
                  'Confidential Document Checklist',
                  style: pw.TextStyle(
                    color: colorForestGreen,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 2,
          decoration: const pw.BoxDecoration(
            color: colorIndianTeal,
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildSchemeSection(SchemeModel scheme, EligibilityResult result) {
    final isMayQualify = result == EligibilityResult.mayQualify;
    final statusBadgeColor =
        isMayQualify ? colorForestGreen : colorMutedAmber;
    final statusText =
        isMayQualify ? 'Eligible (May Qualify)' : 'More Information Needed';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: colorBorderGray, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Bar of Scheme
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: colorWarmSand,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        scheme.name,
                        style: pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (scheme.nameHindi != null &&
                          scheme.nameHindi!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          scheme.nameHindi!,
                          style: const pw.TextStyle(
                            color: colorDeepNavy,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: statusBadgeColor,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    statusText,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scheme Content Details
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Ministry & Benefits
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Ministry: ',
                      style: pw.TextStyle(
                        color: colorDeepNavy,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        scheme.ministry,
                        style: const pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Benefits: ',
                      style: pw.TextStyle(
                        color: colorIndianTeal,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        scheme.benefits,
                        style: const pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Documents Checklist Title
                pw.Text(
                  'Required Documents Checklist:',
                  style: pw.TextStyle(
                    color: colorDeepNavy,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),

                // Document Items with Checkboxes
                if (scheme.requiredDocuments.isEmpty)
                  pw.Text(
                    'No specific mandatory physical documents specified. General photo ID may be required.',
                    style: const pw.TextStyle(
                      color: colorDeepNavy,
                      fontSize: 8,
                    ),
                  )
                else
                  ...scheme.requiredDocuments.map((doc) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 11,
                            height: 11,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: colorDeepNavy,
                                width: 1.2,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(2),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              doc,
                              style: const pw.TextStyle(
                                color: colorDeepNavy,
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                pw.SizedBox(height: 8),
                pw.Divider(color: colorBorderGray, thickness: 0.5),
                pw.SizedBox(height: 6),

                // Official Links
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Official Portal: ',
                      style: pw.TextStyle(
                        color: colorDeepNavy,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.UrlLink(
                        destination: scheme.officialSourceUrl,
                        child: pw.Text(
                          scheme.officialSourceUrl,
                          style: const pw.TextStyle(
                            color: colorIndianTeal,
                            fontSize: 8,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (scheme.applicationUrl != null &&
                    scheme.applicationUrl!.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Apply Online: ',
                        style: pw.TextStyle(
                          color: colorDeepNavy,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.UrlLink(
                          destination: scheme.applicationUrl!,
                          child: pw.Text(
                            scheme.applicationUrl!,
                            style: const pw.TextStyle(
                              color: colorIndianTeal,
                              fontSize: 8,
                              decoration: pw.TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDisclaimerBox() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: colorWarmIvory,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: colorSoftSaffron, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Important Verification Notice & Disclaimer:',
            style: pw.TextStyle(
              color: colorDeepNavy,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. SAHAY is an automated eligibility assessment platform designed to help citizens understand potential entitlements. It is not an official government sanction authority.\n'
            '2. Eligibility indications are indicative and subject to field verification, biometric e-KYC, and scrutiny by designated competent nodal officers.\n'
            '3. Always consult the official government portals listed above or visit your nearest CSC / Gram Panchayat office for the final application submission.\n'
            '4. Keep original documents and self-attested photocopies ready before visiting verification camps.',
            style: const pw.TextStyle(
              color: colorDeepNavy,
              fontSize: 7.5,
              lineSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: colorBorderGray, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SAHAY (सहाय) — Simplifying Access to Welfare Benefits',
              style: const pw.TextStyle(
                color: colorDeepNavy,
                fontSize: 7.5,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                color: colorDeepNavy,
                fontSize: 7.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
