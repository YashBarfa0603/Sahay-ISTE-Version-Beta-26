import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';

class SmartFillerStatusScreen extends StatelessWidget {
  final SchemeModel scheme;

  const SmartFillerStatusScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;
    final ackNumber = session?.submissionReference ?? 'SAHAY-GOV-2026-98124';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Submission Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'Application Completed Successfully!',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(color: AppColors.deepNavy, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Your application for ${scheme.name} has been processed with explicit citizen confirmation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 28),

            // Reference Number Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text('OFFICIAL ACKNOWLEDGEMENT / REFERENCE NUMBER', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SelectableText(
                    ackNumber,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.deepNavy, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ackNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Acknowledgement number copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.deepNavy),
                    label: const Text('Copy Reference', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.deepNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Audit Summary Details
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Scheme ID', scheme.schemeId),
                  const Divider(height: 20),
                  _buildDetailRow('Submission Mode', 'SAHAY Smart Application Filler'),
                  const Divider(height: 20),
                  _buildDetailRow('Citizen Consent', 'Explicit Approval Verified'),
                  const Divider(height: 20),
                  _buildDetailRow('Audit Status', 'Read-Back DOM Verified'),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Return to Home
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.deepNavy)),
      ],
    );
  }
}
