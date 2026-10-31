import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/screens/application/smart_filler_portal_screen.dart';

class SmartFillerMissingInfoScreen extends StatefulWidget {
  final SchemeModel scheme;

  const SmartFillerMissingInfoScreen({super.key, required this.scheme});

  @override
  State<SmartFillerMissingInfoScreen> createState() => _SmartFillerMissingInfoScreenState();
}

class _SmartFillerMissingInfoScreenState extends State<SmartFillerMissingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _dropdownValues = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<ApplicationProvider>().currentSession;
    if (session != null) {
      final missingFields = session.sections
          .expand((s) => s.fields)
          .where((f) => f.isRequired && (f.mappedValue == null || f.mappedValue.toString().trim().isEmpty));
      for (final f in missingFields) {
        if (f.fieldType == FieldType.dropdown && f.options != null && f.options!.isNotEmpty) {
          _dropdownValues[f.fieldId] = f.options!.first;
        } else {
          _controllers[f.fieldId] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showFieldExplanation(BuildContext context, FieldMappingModel field) async {
    final provider = context.read<ApplicationProvider>();
    final exp = await provider.getFieldExplanation(field.fieldId, field.fieldLabel);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.softSaffron, size: 24),
                const SizedBox(width: 8),
                Text(field.fieldLabel, style: AppTextStyles.subheading),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              exp?['explanation'] ?? 'Enter official details as verified on government documents.',
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)),
            ),
            if (exp?['example'] != null && exp!['example']!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('Example: ${exp['example']}', style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepNavy, foregroundColor: Colors.white),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswers() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final answers = <String, dynamic>{};
    _controllers.forEach((k, v) {
      if (v.text.trim().isNotEmpty) {
        answers[k] = v.text.trim();
      }
    });
    _dropdownValues.forEach((k, v) {
      if (v != null) answers[k] = v;
    });

    final success = await context.read<ApplicationProvider>().submitMissingAnswers(answers);
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SmartFillerPortalScreen(scheme: widget.scheme),
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

    final missingFields = session.sections
        .expand((s) => s.fields)
        .where((f) => f.isRequired && (f.mappedValue == null || f.mappedValue.toString().trim().isEmpty))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Required Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  child: const Text('STAGE 3 OF 7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                const Text('Scheme-Specific Inputs', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Expanded(
            child: missingFields.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.forestGreen, size: 56),
                        const SizedBox(height: 14),
                        const Text('All required details are available!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Ready to auto-fill official application portal.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: missingFields.length,
                      itemBuilder: (ctx, idx) {
                        final field = missingFields[idx];
                        return _buildInputFieldCard(context, field);
                      },
                    ),
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
                onPressed: _isSaving ? null : _submitAnswers,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.deepNavy, strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded, color: AppColors.deepNavy),
                label: Text(
                  _isSaving ? 'Saving Answers...' : 'Continue to Official Portal',
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

  Widget _buildInputFieldCard(BuildContext context, FieldMappingModel field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.fieldLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.deepNavy),
                ),
              ),
              InkWell(
                onTap: () => _showFieldExplanation(context, field),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: const [
                      Icon(Icons.help_outline_rounded, size: 16, color: AppColors.deepNavy),
                      SizedBox(width: 4),
                      Text('Explain', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (field.fieldType == FieldType.dropdown && field.options != null && field.options!.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _dropdownValues[field.fieldId] ?? field.options!.first,
              items: field.options!
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) {
                setState(() => _dropdownValues[field.fieldId] = val);
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            TextFormField(
              controller: _controllers[field.fieldId],
              keyboardType: field.fieldType == FieldType.number || field.fieldType == FieldType.phone
                  ? TextInputType.number
                  : TextInputType.text,
              validator: (v) {
                if (field.isRequired && (v == null || v.trim().isEmpty)) {
                  return 'Please enter ${field.fieldLabel}';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter ${field.fieldLabel}',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}

