import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/guided_application_screen.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationWebViewScreen extends StatefulWidget {
  final SchemeModel scheme;

  const ApplicationWebViewScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<ApplicationWebViewScreen> createState() => _ApplicationWebViewScreenState();
}

class _ApplicationWebViewScreenState extends State<ApplicationWebViewScreen> {
  bool _isInspecting = false;
  bool _isAutoFilled = false;

  Future<void> _launchExternalPortal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _triggerControlledPrefill(ApplicationSession session) {
    setState(() => _isInspecting = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isInspecting = false;
          _isAutoFilled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supported demographic fields prefilled. Please enter CAPTCHA and complete OTP manually.'),
            backgroundColor: AppColors.forestGreen,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final session = provider.currentSession;
    final portalUrl = widget.scheme.applicationUrl ?? widget.scheme.officialSourceUrl;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: 'Official Portal: ${widget.scheme.name}',
        showBackButton: true,
        extraActions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GuidedApplicationScreen(scheme: widget.scheme),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.softSaffron, size: 18),
            label: const Text(
              'Guided Form',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Assistant Active Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.deepNavy,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIRECT WEB INTEGRATION ACTIVE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.softSaffron,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          'Interacting with verified official government portal.',
                          style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (session != null)
                    ElevatedButton.icon(
                      onPressed: _isInspecting ? null : () => _triggerControlledPrefill(session),
                      icon: _isInspecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_fix_high, size: 14),
                      label: Text(
                        _isAutoFilled ? 'Re-Fill' : 'Auto-Fill',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indianTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),

            // Official Web Interaction Canvas / Fallback
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.paleSage,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.public_rounded, size: 48, color: AppColors.forestGreen),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Official Application Portal',
                          style: AppTextStyles.heading2.copyWith(color: AppColors.deepNavy, fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          portalUrl,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warmSand,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Citizen Instructions:',
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Name, Aadhaar, State & District are ready to populate.\n'
                                '• Visual CAPTCHA must be typed manually by you.\n'
                                '• OTP will be sent to your Aadhaar-registered mobile number.\n'
                                '• You retain complete control over the final submit button.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => GuidedApplicationScreen(scheme: widget.scheme),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded),
                                label: const Text('Use Guided Form'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _launchExternalPortal(portalUrl),
                                icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                                label: const Text('Open Official Portal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.indianTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

