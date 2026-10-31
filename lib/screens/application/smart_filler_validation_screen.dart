import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_review_screen.dart';

class SmartFillerValidationScreen extends StatelessWidget {
  final SchemeModel scheme;

  const SmartFillerValidationScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;
    final report = appProvider.readBackReport ?? session?.readBackReport;

    final verifiedCount = report?.verifiedCount ?? 0;
    final totalFields = report?.totalFields ?? 0;
    final unverifiedCount = report?.unverifiedCount ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Read-Back Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(20)),
                  child: const Text('STAGE 5 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Field-by-Field Portal Audit', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Verified', '$verifiedCount', AppColors.forestGreen),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildStatItem('Total Fields', '$totalFields', AppColors.deepNavy),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildStatItem('Unverified', '$unverifiedCount', Colors.orange.shade800),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: unverifiedCount == 0 ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              unverifiedCount == 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: unverifiedCount == 0 ? AppColors.forestGreen : Colors.amber.shade900,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                unverifiedCount == 0
                                    ? 'All inspected portal fields match intended citizen data exactly.'
                                    : 'Some fields require portal confirmation or manual entry on the portal.',
                                style: TextStyle(
                                  color: unverifiedCount == 0 ? Colors.green.shade900 : Colors.amber.shade900,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Inspected Portal Elements:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.deepNavy),
                ),
                const SizedBox(height: 10),

                // Items list
                if (report != null && report.items.isNotEmpty)
                  ...report.items.map((item) => _buildVerificationItemTile(item))
                else if (session != null)
                  ...session.sections.expand((s) => s.fields).map((f) => _buildFallbackFieldTile(f)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SmartFillerReviewScreen(scheme: scheme),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.deepNavy),
                label: const Text(
                  'Proceed to Final Review',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softSaffron,
                  foregroundColor: AppColors.deepNavy,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVerificationItemTile(ReadBackFieldItemModel item) {
    final isVerified = item.status == ReadBackFieldStatus.filledVerified;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.warning_rounded,
            color: isVerified ? AppColors.forestGreen : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fieldId.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.deepNavy),
                ),
                Text(
                  item.message ?? (isVerified ? 'Verified in DOM' : 'Pending verification'),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            item.expectedValue?.toString() ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.deepNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackFieldTile(FieldMappingModel field) {
    final hasVal = field.mappedValue != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            hasVal ? Icons.check_circle : Icons.help_outline,
            color: hasVal ? AppColors.forestGreen : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field.fieldLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepNavy),
            ),
          ),
          Text(
            hasVal ? field.mappedValue.toString() : 'Empty',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.deepNavy),
          ),
        ],
      ),
    );
  }
}

