import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationReviewScreen extends StatefulWidget {
  final SchemeModel scheme;

  const ApplicationReviewScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen> {
  bool _userExplicitApproval = false;
  bool _isSubmitting = false;

  Future<void> _launchPortalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleFinalSubmission(BuildContext context, ApplicationProvider provider) async {
    if (!_userExplicitApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the authorization declaration before proceeding.'),
          backgroundColor: AppColors.mutedCoral,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await provider.confirmFinalSubmission(userApproved: true);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final session = provider.currentSession;
    final ack = session?.submissionReference ?? 'SAHAY-ACK-CONFIRMED';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 28),
            SizedBox(width: 10),
            Text('Application Verified', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your application details have been validated and compiled with official portal requirements.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warmSand,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acknowledgement / Reference:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(
                    ack,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.indianTeal, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Next Steps: Complete any mandatory OTP/biometric verification on the official portal.',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          if (widget.scheme.applicationUrl != null)
            TextButton.icon(
              onPressed: () => _launchPortalUrl(widget.scheme.applicationUrl!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Portal'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indianTeal, foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final session = provider.currentSession;

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: const SahayAppBar(
        title: 'Review Application',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // Scheme Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.scheme.name,
                          style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Category: ${widget.scheme.category.toUpperCase()}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.softSaffron, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.forestGreen),
                            const SizedBox(width: 6),
                            Text(
                              session.canSubmit ? 'All mandatory fields completed' : 'Missing mandatory fields',
                              style: AppTextStyles.caption.copyWith(
                                color: session.canSubmit ? AppColors.paleSage : AppColors.mutedCoral,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Breakdown Cards
                  Text(
                    'Compiled Information Summary',
                    style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 12),

                  ...session.sections.map((sec) => _buildSectionReview(sec)),

                  const SizedBox(height: 20),

                  // Mandatory Citizen Approval Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _userExplicitApproval ? AppColors.forestGreen : AppColors.border,
                        width: _userExplicitApproval ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _userExplicitApproval,
                          activeColor: AppColors.forestGreen,
                          onChanged: (val) {
                            setState(() => _userExplicitApproval = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _userExplicitApproval = !_userExplicitApproval);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'I solemnly declare that all information provided above is true to the best of my knowledge. I authorize SAHAY to compile this application for the official government portal.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.deepNavy,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Submit Button Action
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _handleFinalSubmission(context, provider),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Validating...' : 'Confirm & Proceed to Official Portal',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userExplicitApproval ? AppColors.forestGreen : AppColors.indianTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionReview(ApplicationSectionModel section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.heading3.copyWith(fontSize: 15, color: AppColors.deepNavy),
          ),
          const Divider(height: 18),
          ...section.fields.map((f) {
            final val = f.mappedValue?.toString() ?? 'Not Provided';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      f.fieldLabel,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Text(
                      val,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

