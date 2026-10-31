import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_info_review_screen.dart';

class SmartFillerPreparationScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerPreparationScreen({super.key, required this.scheme});

  @override
  State<SmartFillerPreparationScreen> createState() => _SmartFillerPreparationScreenState();
}

class _SmartFillerPreparationScreenState extends State<SmartFillerPreparationScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;
    final registryEntry = appProvider.getRegistryEntry(widget.scheme.schemeId);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Smart Application Filler'),
          backgroundColor: AppColors.deepNavy,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.softSaffron),
        ),
      );
    }

    final allFields = session.sections.expand((s) => s.fields).toList();
    final totalFields = allFields.length;
    final readyFields = allFields.where((f) => f.mappedValue != null && f.mappedValue.toString().trim().isNotEmpty).length;
    final readinessPercent = totalFields > 0 ? ((readyFields / totalFields) * 100).toInt() : 0;
    final missingCount = session.missingFieldsCount;
    final conflictCount = session.conflictsCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Smart Application Assistant',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Indicator Progress Header
            _buildStageHeader(stage: 1, title: 'Application Preparation'),
            const SizedBox(height: 18),

            // Scheme Headline Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepNavy, Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softSaffron,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '10-SCHEME VERIFIED',
                          style: TextStyle(
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.verified, color: AppColors.softSaffron, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.scheme.name,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Official Portal: ${registryEntry?.portalDomain ?? widget.scheme.applicationUrl ?? "Government Portal"}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Readiness Meter Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Profile Data Readiness', style: AppTextStyles.subheading),
                      const Spacer(),
                      Text(
                        '$readinessPercent%',
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: readinessPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMiniBadge(Icons.check_circle_rounded, '$readyFields Available', AppColors.forestGreen),
                      const SizedBox(width: 12),
                      _buildMiniBadge(Icons.help_outline_rounded, '$missingCount Missing', AppColors.softSaffron),
                      if (conflictCount > 0) ...[
                        const SizedBox(width: 12),
                        _buildMiniBadge(Icons.warning_amber_rounded, '$conflictCount Conflict', Colors.red.shade700),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Manual Interventions & Requirements Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.deepNavy, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'What SAHAY Fills vs Your Part',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.deepNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBulletRow(Icons.auto_awesome, 'SAHAY automatically inputs verified demographic, address, income & bank details directly into portal inputs.'),
                  const SizedBox(height: 10),
                  _buildBulletRow(Icons.pin, 'You manually enter OTP & CAPTCHA as required by government security protocols.'),
                  const SizedBox(height: 10),
                  _buildBulletRow(Icons.lock, 'No auto-submission: You review every detail and approve before submission.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Next Step Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SmartFillerInfoReviewScreen(scheme: widget.scheme),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.deepNavy),
                label: const Text(
                  'Review Retrieved Profile Data',
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
          ],
        ),
      ),
    );
  }

  static Widget _buildStageHeader({required int stage, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'STAGE $stage OF 7',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.deepNavy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF374151), fontSize: 13.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}
