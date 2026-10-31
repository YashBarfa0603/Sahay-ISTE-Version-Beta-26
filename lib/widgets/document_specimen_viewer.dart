import 'package:flutter/material.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/document_info_model.dart';

/// Renders an educational illustrative sample/specimen of an Indian government
/// document with prominent disclaimers preventing misrepresentation.
class DocumentSpecimenViewer extends StatelessWidget {
  final DocumentInfoModel documentInfo;
  final String language;

  const DocumentSpecimenViewer({
    super.key,
    required this.documentInfo,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final isHi = language == 'hi';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softSaffron.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Specimen Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.softSaffron,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.policy_outlined,
                  size: 16,
                  color: AppColors.deepNavy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHi
                        ? 'नमूना प्रारूप — केवल संदर्भ हेतु'
                        : 'OFFICIAL SPECIMEN LAYOUT — FOR GUIDANCE ONLY',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SAMPLE',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Specimen Card Body (Simulated Document Paper)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBF6), // Warm parchment
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD6D1BF),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Diagonal Watermark
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Text(
                          'SPECIMEN / नमूना',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withValues(alpha: 0.05),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Mockup Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Seal and Authority
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.deepNavy.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.indianTeal, width: 1.2),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color: AppColors.indianTeal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHi
                                      ? documentInfo.issuingAuthorityHindi
                                      : documentInfo.issuingAuthority,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepNavy,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  documentInfo.specimenTitle,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.indianTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE2DEC9)),
                      const SizedBox(height: 12),

                      // Document-specific visual fields mockup
                      _buildSpecimenFields(documentInfo, isHi),

                      const SizedBox(height: 12),

                      // Layout Description Note
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.steelBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                documentInfo.specimenDescription,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.deepNavy.withValues(alpha: 0.8),
                                  fontSize: 10.5,
                                  height: 1.35,
                                ),
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
          ),

          // Bottom Official Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warmSand.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: AppColors.steelBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHi
                        ? 'महत्वपूर्ण सूचना: यह केवल एक उदाहरणात्मक नमूना है। वास्तविक दस्तावेज़ का प्रारूप राज्य, जारीकर्ता वर्ष और संबंधित प्राधिकरण के अनुसार भिन्न हो सकता है।'
                        : 'Notice: Illustrative sample only. Actual document formats and security watermarks vary by issuing state and authority.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.75),
                      fontSize: 10,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecimenFields(DocumentInfoModel doc, bool isHi) {
    switch (doc.documentType) {
      case 'aadhaar_card':
        return Row(
          children: [
            Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Icon(Icons.person, size: 36, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAME / नाम: CITIZEN NAME',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'DOB / जन्मतिथि: DD/MM/YYYY',
                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'GENDER / लिंग: MALE / FEMALE',
                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.grey.shade100,
                    child: Text(
                      'XXXX  XXXX  1234',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'bank_passbook':
        return Column(
          children: [
            _buildDataRow('Account No / खाता संख्या:', 'XXXXXXXX9876'),
            _buildDataRow('IFSC Code / आईएफएससी:', 'SBIN0001234'),
            _buildDataRow('Account Holder:', 'CITIZEN NAME'),
            _buildDataRow('Aadhaar / DBT Seeding:', 'ACTIVE / YES'),
          ],
        );

      case 'land_ownership_record':
        return Column(
          children: [
            _buildDataRow('Khata No / खाता संख्या:', '00142'),
            _buildDataRow('Khasra / Gata No:', '124/1, 125/2'),
            _buildDataRow('Cultivable Area:', '1.450 Hectares'),
            _buildDataRow('Tehsil / District:', 'Sadar / Sample District'),
          ],
        );

      case 'samagra_id':
        return Column(
          children: [
            _buildDataRow('Family ID (परिवार आईडी):', '87654321 (8 Digits)'),
            _buildDataRow('Member ID (सदस्य आईडी):', '123456789 (9 Digits)'),
            _buildDataRow('e-KYC Status:', 'COMPLETED (सत्यापित)'),
            _buildDataRow('Bank Account Linked:', 'YES / हां'),
          ],
        );

      case 'ration_card':
        return Column(
          children: [
            _buildDataRow('Card No / राशन कार्ड सं.:', '230100456789'),
            _buildDataRow('Category / श्रेणी:', 'PHH / BPL (Priority Household)'),
            _buildDataRow('Head of Family:', 'FEMALE HEAD / महिला मुखिया'),
            _buildDataRow('Total Members / सदस्य:', '4 Members (All Aadhaar Linked)'),
          ],
        );

      default:
        return Column(
          children: [
            _buildDataRow('Document Type:', doc.displayName),
            _buildDataRow('Certificate ID:', 'GOV-IND-2026-XXXX'),
            _buildDataRow('Status:', 'OFFICIALLY VALID'),
          ],
        );
    }
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
          ),
        ],
      ),
    );
  }
}

