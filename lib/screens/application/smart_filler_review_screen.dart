import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_status_screen.dart';

class SmartFillerReviewScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerReviewScreen({super.key, required this.scheme});

  @override
  State<SmartFillerReviewScreen> createState() => _SmartFillerReviewScreenState();
}

class _SmartFillerReviewScreenState extends State<SmartFillerReviewScreen> {
  bool _explicitApprovalGiven = false;
  bool _isSubmitting = false;

  void _submitApplication() async {
    if (!_explicitApprovalGiven) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<ApplicationProvider>();
    final success = await provider.confirmFinalSubmission(userApproved: true);

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SmartFillerStatusScreen(scheme: widget.scheme),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm submission. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Final Citizen Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  child: const Text('STAGE 6 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Explicit Citizen Gate', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Scheme Summary Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.softSaffron, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.description, color: AppColors.deepNavy, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.scheme.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.deepNavy)),
                            const SizedBox(height: 4),
                            Text('Session ID: ${session.sessionId}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Review Sections
                ...session.sections.map((sec) => _buildReviewSection(sec)),

                const SizedBox(height: 12),

                // Mandatory Citizen Declaration Gate
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.gavel, color: Color(0xFF1D4ED8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Mandatory Legal Declaration',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1D4ED8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _explicitApprovalGiven,
                            activeColor: AppColors.deepNavy,
                            onChanged: (val) {
                              setState(() => _explicitApprovalGiven = val ?? false);
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _explicitApprovalGiven = !_explicitApprovalGiven);
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'I explicitly declare that all information shown above has been verified by me and is true to the best of my knowledge. I authorize SAHAY to finalize and submit my application to the official government portal.',
                                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                onPressed: _explicitApprovalGiven && !_isSubmitting ? _submitApplication : null,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.deepNavy, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: AppColors.deepNavy),
                label: Text(
                  _isSubmitting ? 'Finalizing Application...' : 'Confirm & Finalize Application',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softSaffron,
                  foregroundColor: AppColors.deepNavy,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: _explicitApprovalGiven ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(ApplicationSectionModel section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.deepNavy),
            ),
          ),
          ...section.fields.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(f.fieldLabel, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      f.mappedValue?.toString() ?? '—',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.deepNavy),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

