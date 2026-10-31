import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/application_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/application/application_review_screen.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';

class GuidedApplicationScreen extends StatefulWidget {
  final SchemeModel scheme;

  const GuidedApplicationScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<GuidedApplicationScreen> createState() => _GuidedApplicationScreenState();
}

class _GuidedApplicationScreenState extends State<GuidedApplicationScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String fieldId, dynamic initialValue) {
    if (!_controllers.containsKey(fieldId)) {
      _controllers[fieldId] = TextEditingController(text: initialValue?.toString() ?? '');
    }
    return _controllers[fieldId]!;
  }

  void _showExplanationSheet(
    BuildContext context,
    FieldMappingModel field,
    String language,
    ApplicationProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: FutureBuilder<Map<String, String>?>(
            future: provider.getFieldExplanation(field.fieldId, field.fieldLabel, language: language),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: AppColors.indianTeal)),
                );
              }
              final exp = snapshot.data?['explanation'] ?? field.explanation ?? 'Provide accurate information matching your documents.';
              final ex = snapshot.data?['example'];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.softSaffron.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.deepNavy, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field.fieldLabel,
                          style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'AI Field Explanation (सहाय AI व्याख्या):',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.indianTeal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exp,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy, height: 1.5, fontSize: 14.5),
                  ),
                  if (ex != null && ex.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warmSand,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.forestGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ex,
                              style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final session = provider.currentSession;
    final locale = context.watch<LocaleProvider>().languageCode;

    if (session == null) {
      return Scaffold(
        appBar: const SahayAppBar(title: 'Application Assistant', showBackButton: true),
        body: const Center(child: CircularProgressIndicator(color: AppColors.indianTeal)),
      );
    }

    final totalFields = session.sections.fold<int>(0, (sum, sec) => sum + sec.fields.length);
    final completedFields = session.sections.fold<int>(
      0,
      (sum, sec) => sum + sec.fields.where((f) => f.mappedValue != null && f.mappedValue.toString().isNotEmpty).length,
    );
    final progress = totalFields > 0 ? (completedFields / totalFields) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: 'Apply: ${widget.scheme.name}',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Banner
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: AppColors.deepNavy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softSaffron,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SAHAY GUIDED FORM',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$completedFields of $totalFields completed',
                        style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                    ),
                  ),
                ],
              ),
            ),

            // Form Sections List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Verification & Security Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.paleSage,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.forestGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Fields prefilled from your profile and documents. You can review and edit every answer.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sections
                  ...session.sections.map((section) => _buildSectionCard(context, section, locale, provider)),

                  // Document Checklist Card
                  if (session.documents.isNotEmpty)
                    _buildDocumentsCard(context, session.documents),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider.validateSession();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApplicationReviewScreen(scheme: widget.scheme),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
                  label: const Text(
                    'Review Application',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indianTeal,
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

  Widget _buildSectionCard(
    BuildContext context,
    ApplicationSectionModel section,
    String language,
    ApplicationProvider provider,
  ) {
    final title = (language == 'hi' && section.titleHi != null) ? section.titleHi! : section.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          title: Text(
            title,
            style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy, fontSize: 16),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: section.fields.map((f) => _buildFieldItem(context, f, language, provider)).toList(),
        ),
      ),
    );
  }

  Widget _buildFieldItem(
    BuildContext context,
    FieldMappingModel field,
    String language,
    ApplicationProvider provider,
  ) {
    final label = (language == 'hi' && field.fieldLabelHi != null) ? field.fieldLabelHi! : field.fieldLabel;
    final controller = _getController(field.fieldId, field.mappedValue);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: field.conflictDetected
              ? AppColors.mutedCoral
              : (field.mappingStatus == MappingStatus.prefilled ? AppColors.indianTeal.withValues(alpha: 0.4) : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label and Metadata Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      if (field.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: AppColors.mutedCoral, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // AI Explanation Button
              InkWell(
                onTap: () => _showExplanationSheet(context, field, language, provider),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softSaffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.deepNavy),
                      const SizedBox(width: 4),
                      Text(
                        'Explain',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Status Badge
          const SizedBox(height: 6),
          _buildFieldStatusBadge(field),

          // Conflict Resolution Banner
          if (field.conflictDetected && field.conflictDetails != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mutedCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.mutedCoral.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discrepancy Detected between Profile & Document:',
                    style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final pVal = field.conflictDetails!['profile_value'];
                            controller.text = pVal?.toString() ?? '';
                            provider.resolveConflict(field.fieldId, pVal);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                          child: Text(
                            'Use Profile: ${field.conflictDetails!['profile_value']}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final dVal = field.conflictDetails!['document_value'];
                            controller.text = dVal?.toString() ?? '';
                            provider.resolveConflict(field.fieldId, dVal);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                          child: Text(
                            'Use Doc: ${field.conflictDetails!['document_value']}',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Input Control based on type
          const SizedBox(height: 10),
          if (field.fieldType == FieldType.dropdown && field.options != null && field.options!.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: field.options!.contains(field.mappedValue?.toString()) ? field.mappedValue.toString() : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              ),
              items: field.options!
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: AppTextStyles.bodyMedium)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  provider.updateField(field.fieldId, val);
                }
              },
            )
          else if (field.fieldType == FieldType.radio && field.options != null)
            Row(
              children: field.options!.map((opt) {
                final isSelected = field.mappedValue?.toString().toLowerCase() == opt.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    selectedColor: AppColors.indianTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.deepNavy,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.updateField(field.fieldId, opt);
                      }
                    },
                  ),
                );
              }).toList(),
            )
          else
            TextFormField(
              controller: controller,
              keyboardType: field.fieldType == FieldType.number || field.fieldType == FieldType.phone
                  ? TextInputType.number
                  : TextInputType.text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                hintText: 'Enter ${field.fieldLabel}',
                hintStyle: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
              onChanged: (val) {
                provider.updateField(field.fieldId, val.trim());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFieldStatusBadge(FieldMappingModel field) {
    if (field.conflictDetected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.mutedCoral.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: Text('Conflict Needs Choice', style: AppTextStyles.caption.copyWith(color: AppColors.mutedCoral, fontWeight: FontWeight.bold, fontSize: 10)),
      );
    }
    if (field.mappingStatus == MappingStatus.userConfirmed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.forestGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: Text('User Confirmed', style: AppTextStyles.caption.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 10)),
      );
    }
    if (field.mappingStatus == MappingStatus.prefilled) {
      final src = field.sourceType == SourceType.uploadedDocument ? 'Document' : 'Profile';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.indianTeal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: Text('Prefilled from $src', style: AppTextStyles.caption.copyWith(color: AppColors.indianTeal, fontWeight: FontWeight.bold, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text('Required Input', style: AppTextStyles.caption.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, List<DocumentRequirementModel> docs) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_outlined, color: AppColors.indianTeal, size: 20),
              const SizedBox(width: 10),
              Text(
                'Required Documents Checklist',
                style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.map((d) {
            final isAttached = d.status == 'attached' || d.status == 'ocr_processed';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    isAttached ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isAttached ? AppColors.forestGreen : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.documentName,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAttached ? AppColors.paleSage : AppColors.warmSand,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAttached ? 'OCR Verified' : 'To Bring',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAttached ? AppColors.forestGreen : AppColors.deepNavy,
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

