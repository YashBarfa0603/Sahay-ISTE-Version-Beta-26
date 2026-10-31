import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_missing_info_screen.dart';
import 'package:sahay/screens/application/smart_filler_portal_screen.dart';

class SmartFillerInfoReviewScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerInfoReviewScreen({super.key, required this.scheme});

  @override
  State<SmartFillerInfoReviewScreen> createState() => _SmartFillerInfoReviewScreenState();
}

class _SmartFillerInfoReviewScreenState extends State<SmartFillerInfoReviewScreen> {
  void _showConflictDialog(BuildContext context, FieldMappingModel field) {
    final details = field.conflictDetails ?? {};
    final profileVal = details['profile_value'] ?? field.mappedValue;
    final docVal = details['document_value'] ?? 'Extracted Value';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Resolve Conflict', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discrepancy detected for "${field.fieldLabel}":',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              title: 'Use Profile Value: ₹$profileVal',
              subtitle: 'From your SAHAY profile questionnaire',
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<ApplicationProvider>().resolveConflict(field.fieldId, profileVal);
              },
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              title: 'Use Document Value: ₹$docVal',
              subtitle: 'Extracted from your uploaded Income Certificate',
              isHighlighted: true,
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<ApplicationProvider>().resolveConflict(field.fieldId, docVal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.softSaffron.withValues(alpha: 0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlighted ? AppColors.softSaffron : Colors.grey.shade300,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final session = appProvider.currentSession;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final missingCount = session.missingFieldsCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Review Retrieved Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  child: const Text('STAGE 2 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Data Provenance & Verification', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: session.sections.length,
              itemBuilder: (ctx, idx) {
                final section = session.sections[idx];
                return _buildSectionCard(context, section);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (missingCount > 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SmartFillerMissingInfoScreen(scheme: widget.scheme),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SmartFillerPortalScreen(scheme: widget.scheme),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.deepNavy),
                label: Text(
                  missingCount > 0 ? 'Provide Missing Details ($missingCount items)' : 'Proceed to Portal Auto-Fill',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

  Widget _buildSectionCard(BuildContext context, ApplicationSectionModel section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(section.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.deepNavy)),
                const Spacer(),
                Text('${section.fields.length} fields', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          ...section.fields.map((f) => _buildFieldRow(context, f)),
        ],
      ),
    );
  }

  Widget _buildFieldRow(BuildContext context, FieldMappingModel field) {
    final hasVal = field.mappedValue != null && field.mappedValue.toString().trim().isNotEmpty;
    final isConflict = field.conflictDetected && !field.userConfirmed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.fieldLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  hasVal ? field.mappedValue.toString() : 'Not provided yet',
                  style: TextStyle(
                    fontWeight: hasVal ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    color: hasVal ? AppColors.deepNavy : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 6),
                _buildProvenanceBadge(field),
              ],
            ),
          ),
          if (isConflict)
            ElevatedButton.icon(
              onPressed: () => _showConflictDialog(context, field),
              icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
              label: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            Icon(
              hasVal ? Icons.check_circle_rounded : Icons.pending_outlined,
              size: 20,
              color: hasVal ? AppColors.forestGreen : Colors.grey.shade300,
            ),
        ],
      ),
    );
  }

  Widget _buildProvenanceBadge(FieldMappingModel field) {
    if (field.provenance != null) {
      final src = field.provenance!.source;
      final isOcr = src.contains('ocr') || src.contains('doc');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isOcr ? Colors.purple.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isOcr ? 'Source: Document Vault OCR' : 'Source: Citizen Profile',
          style: TextStyle(
            color: isOcr ? Colors.purple.shade700 : Colors.blue.shade800,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

