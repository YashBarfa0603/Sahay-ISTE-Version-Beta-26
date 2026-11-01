import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/utils/indian_states.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';

/// Dedicated screen for providing only the missing or unresolved information
/// required to determine eligibility for a specific scheme.
class SchemeMissingInfoScreen extends StatefulWidget {
  final SchemeModel scheme;
  final EligibilityModel? eligibility;

  const SchemeMissingInfoScreen({
    super.key,
    required this.scheme,
    this.eligibility,
  });

  @override
  State<SchemeMissingInfoScreen> createState() => _SchemeMissingInfoScreenState();
}

class _SchemeMissingInfoScreenState extends State<SchemeMissingInfoScreen> {
  late final List<QuestionItem> _missingQuestions;
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _validationErrorMessage;

  @override
  void initState() {
    super.initState();
    final userAnswers = context.read<UserProfileProvider>().answers;
    _missingQuestions = const QuestionEngine().getMissingQuestionsForScheme(
      widget.scheme,
      userAnswers,
      assessment: widget.eligibility,
    );

    for (final q in _missingQuestions) {
      final existingVal = userAnswers[q.id] ??
          userAnswers[const QuestionEngine().mapFieldToQuestionId(q.id)];
      if (existingVal != null) {
        _answers[q.id] = existingVal;
      }
      if (q.type == 'number' || q.type == 'text') {
        _controllers[q.id] = TextEditingController(
          text: existingVal != null ? existingVal.toString() : '',
        );
        _focusNodes[q.id] = FocusNode();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _formatOptionLabel(String option, BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    switch (option.toLowerCase()) {
      case 'male':
        return l10n.male;
      case 'female':
        return l10n.female;
      case 'other':
        return l10n.other;
      case 'rural':
        return l10n.rural;
      case 'urban':
        return l10n.urban;
      case 'semi_urban':
        return l10n.semiUrban;
      case 'farmer':
        return l10n.farmer;
      case 'student':
        return l10n.student;
      case 'unemployed':
        return l10n.unemployed;
      case 'homemaker':
        return l10n.homemaker;
      case 'retired':
        return l10n.retired;
      case 'general':
        return l10n.general;
      case 'obc':
        return l10n.obc;
      case 'sc':
        return l10n.sc;
      case 'st':
        return l10n.st;
      case 'single':
      case 'unmarried':
        return l10n.single;
      case 'married':
        return l10n.married;
      case 'widowed':
        return l10n.widowed;
      case 'divorced':
        return l10n.divorced;
      case 'yes':
        return l10n.yes;
      case 'no':
        return l10n.no;
      default:
        final replaced = option.replaceAll('_', ' ');
        if (replaced.isEmpty) return option;
        return replaced[0].toUpperCase() + replaced.substring(1);
    }
  }

  Future<void> _submitAnswers() async {
    FocusScope.of(context).unfocus();

    // Validate that all missing questions have been answered
    for (final q in _missingQuestions) {
      if (q.type == 'number') {
        final text = _controllers[q.id]?.text.trim();
        if (text == null || text.isEmpty) {
          setState(() {
            _validationErrorMessage =
                SahayLocalizations.of(context).pleaseFillAllFields;
          });
          return;
        }
        final parsed = num.tryParse(text);
        if (parsed == null) {
          setState(() {
            _validationErrorMessage = 'Please enter a valid number';
          });
          return;
        }
        _answers[q.id] = parsed;
      } else if (q.type == 'text') {
        final text = _controllers[q.id]?.text.trim();
        if (text == null || text.isEmpty) {
          setState(() {
            _validationErrorMessage =
                SahayLocalizations.of(context).pleaseFillAllFields;
          });
          return;
        }
        _answers[q.id] = text;
      } else {
        if (!_answers.containsKey(q.id) || _answers[q.id] == null) {
          setState(() {
            _validationErrorMessage =
                SahayLocalizations.of(context).pleaseFillAllFields;
          });
          return;
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _validationErrorMessage = null;
    });

    try {
      final userProfile = context.read<UserProfileProvider>();
      final eligibilityProvider = context.read<EligibilityProvider>();
      final schemeProvider = context.read<SchemeProvider>();
      final authProvider = context.read<AuthProvider>();

      // 1. Merge into UserProfileProvider (preserves existing answers)
      userProfile.setAnswers(_answers);

      // 2. Re-evaluate single scheme
      final updatedAssessment = eligibilityProvider.evaluateSingle(
        widget.scheme,
        userProfile.answers,
      );

      // 3. Re-evaluate all schemes so results lists and counts update
      if (schemeProvider.schemes.isNotEmpty) {
        eligibilityProvider.evaluateAll(
          schemeProvider.schemes,
          userProfile.answers,
        );
      }

      // 4. Update profile for authenticated users
      if (!authProvider.isGuest && authProvider.currentUser != null) {
        try {
          await authProvider.updateProfile(_answers);
        } catch (err) {
          debugPrint('SchemeMissingInfoScreen non-fatal auth sync error: $err');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAssessment.result == EligibilityResult.mayQualify
                  ? 'Information updated! You may qualify for this scheme.'
                  : (updatedAssessment.result == EligibilityResult.doesNotQualify
                      ? 'Information updated! Scheme criteria evaluated.'
                      : 'Information updated successfully!'),
            ),
            backgroundColor:
                updatedAssessment.result == EligibilityResult.mayQualify
                    ? AppColors.forestGreen
                    : AppColors.deepNavy,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(updatedAssessment);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _validationErrorMessage = 'Error updating information: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;

    final displayName = (currentLang == 'hi' &&
            widget.scheme.nameHindi != null &&
            widget.scheme.nameHindi!.isNotEmpty)
        ? widget.scheme.nameHindi!
        : widget.scheme.name;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: l10n.additionalInfoRequired,
        showBackButton: true,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scheme Banner Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.steelBlue.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.steelBlue
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l10n.additionalInfoRequired,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.steelBlue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.help_outline_rounded,
                                    color: AppColors.steelBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 18,
                                  color: AppColors.deepNavy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.missingInfoDesc,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Error Banner if validation fails
                        if (_validationErrorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.mutedCoral.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.mutedCoral.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.mutedCoral,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationErrorMessage!,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.mutedCoral,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Missing Questions List
                        if (_missingQuestions.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppColors.forestGreen,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.allInformationProvided,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.deepNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ...List.generate(_missingQuestions.length, (index) {
                            final q = _missingQuestions[index];
                            return _buildQuestionCard(
                              q,
                              index + 1,
                              _missingQuestions.length,
                              currentLang,
                              l10n,
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Submit & Check Eligibility Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAnswers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indianTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.submitAndCheckEligibility,
                                style: AppTextStyles.label.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    QuestionItem q,
    int index,
    int total,
    String currentLang,
    SahayLocalizations l10n,
  ) {
    final label = (currentLang == 'hi' &&
            q.labelHindi != null &&
            q.labelHindi!.isNotEmpty)
        ? q.labelHindi!
        : (q.label ?? q.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paleSage,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Requirement $index of $total',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16,
              color: AppColors.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (q.helperText != null && q.helperText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              q.helperText!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildInputControl(q, currentLang, l10n),
        ],
      ),
    );
  }

  Widget _buildInputControl(
    QuestionItem q,
    String currentLang,
    SahayLocalizations l10n,
  ) {
    if (q.type == 'boolean') {
      final selectedVal = _answers[q.id];
      return Row(
        children: [
          Expanded(
            child: _buildChoiceTile(
              title: l10n.yes,
              isSelected: selectedVal == true,
              onTap: () {
                setState(() => _answers[q.id] = true);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildChoiceTile(
              title: l10n.no,
              isSelected: selectedVal == false,
              onTap: () {
                setState(() => _answers[q.id] = false);
              },
            ),
          ),
        ],
      );
    }

    if (q.type == 'number') {
      final controller = _controllers[q.id];
      final focusNode = _focusNodes[q.id];
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.paleSage.withValues(alpha: 0.5),
          hintText: q.unit != null ? 'Enter value in ${q.unit}' : 'Enter amount',
          suffixText: q.unit,
          suffixStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
    }

    if (q.id == 'state') {
      final selectedState = _answers['state'] as String?;
      return DropdownButtonFormField<String>(
        initialValue: selectedState,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.paleSage.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        hint: Text(l10n.selectState),
        isExpanded: true,
        items: IndianStates.allStates.map((s) {
          return DropdownMenuItem<String>(
            value: s.code,
            child: Text(
              s.getLocalizedName(currentLang),
              style: AppTextStyles.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() => _answers['state'] = val);
        },
      );
    }

    if (q.type == 'single_choice' && q.options != null && q.options!.isNotEmpty) {
      final selectedOption = _answers[q.id]?.toString();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: q.options!.map((opt) {
          final isSelected = selectedOption == opt;
          final optLabel = _formatOptionLabel(opt, context);
          return ChoiceChip(
            label: Text(optLabel),
            selected: isSelected,
            selectedColor: AppColors.indianTeal,
            backgroundColor: AppColors.paleSage.withValues(alpha: 0.6),
            labelStyle: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.deepNavy,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.indianTeal : Colors.transparent,
              ),
            ),
            onSelected: (selected) {
              setState(() {
                _answers[q.id] = selected ? opt : null;
              });
            },
          );
        }).toList(),
      );
    }

    // Default: text field
    final controller = _controllers[q.id];
    final focusNode = _focusNodes[q.id];
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.paleSage.withValues(alpha: 0.5),
        hintText: 'Enter details',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indianTeal : AppColors.paleSage.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.indianTeal : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.deepNavy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
