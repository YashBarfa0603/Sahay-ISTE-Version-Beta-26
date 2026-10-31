import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_validation_screen.dart';

class SmartFillerPortalScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerPortalScreen({super.key, required this.scheme});

  @override
  State<SmartFillerPortalScreen> createState() => _SmartFillerPortalScreenState();
}

class _SmartFillerPortalScreenState extends State<SmartFillerPortalScreen> {
  bool _isAutoFilling = false;
  bool _isAutoFilled = false;
  final Map<String, dynamic> _mockDomValues = {};

  @override
  void initState() {
    super.initState();
    _initPayloadAndSimulateFill();
  }

  Future<void> _initPayloadAndSimulateFill() async {
    final provider = context.read<ApplicationProvider>();
    setState(() => _isAutoFilling = true);

    await provider.fetchPortalPopulationPayload();

    // Populate mock DOM simulation state with mapped values from session
    final session = provider.currentSession;
    if (session != null) {
      for (final sec in session.sections) {
        for (final f in sec.fields) {
          if (f.mappedValue != null) {
            _mockDomValues[f.fieldId] = f.mappedValue;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAutoFilling = false;
        _isAutoFilled = true;
      });
    }
  }

  void _triggerReadBackAndProceed() async {
    final provider = context.read<ApplicationProvider>();
    await provider.verifyReadBack(_mockDomValues);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartFillerValidationScreen(scheme: widget.scheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;
    final targetUrl = widget.scheme.applicationUrl ?? 'https://pmkisan.gov.in';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Portal Auto-Fill Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Assistant Header & Stage Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(20)),
                  child: const Text('STAGE 4 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Portal Autofill & Verification', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),

          // Portal Target URL & Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                const Icon(Icons.language, color: AppColors.softSaffron, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    targetUrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, overflow: TextOverflow.ellipsis),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isAutoFilled ? AppColors.forestGreen : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isAutoFilled ? 'POPULATED' : 'FILLING...',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Mandatory Manual Action Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF92400E), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manual Action: Visual CAPTCHA and OTP must be entered directly by you.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Live Portal Simulation / Inspection Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          const Icon(Icons.security, size: 16, color: AppColors.forestGreen),
                          const SizedBox(width: 6),
                          const Text(
                            'Official Government Portal View (Sandbox Bridge)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                          ),
                          const Spacer(),
                          if (_isAutoFilling)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Field Population Log & DOM Mapping:',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.deepNavy),
                          ),
                          const SizedBox(height: 12),
                          if (session != null)
                            ...session.sections.expand((s) => s.fields).map((f) {
                              final isFilled = f.mappedValue != null && f.mappedValue.toString().trim().isNotEmpty;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isFilled ? Colors.green.shade50 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isFilled ? Colors.green.shade200 : Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isFilled ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: isFilled ? AppColors.forestGreen : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            f.fieldLabel,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          Text(
                                            'Selector: ${f.portalSelector ?? f.fieldId}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      isFilled ? (f.mappedValue.toString()) : 'Empty',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isFilled ? AppColors.deepNavy : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar to Run Read-Back
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
                onPressed: _triggerReadBackAndProceed,
                icon: const Icon(Icons.fact_check_rounded, color: AppColors.deepNavy),
                label: const Text(
                  'Verify Portal Inputs (Read-Back)',
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
}

