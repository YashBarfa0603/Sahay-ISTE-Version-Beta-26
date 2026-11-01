import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/widgets/income_estimation_modal.dart';
import 'package:sahay/widgets/voice_input_button.dart';

class QuestionCard extends StatefulWidget {
  final QuestionItem question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool isMandatory;
  final int? currentStep;
  final int? totalSteps;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
    required this.onNext,
    this.onSkip,
    this.isMandatory = false,
    this.currentStep,
    this.totalSteps,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final TextEditingController _textController;
  Timer? _advanceTimer;

  void _handleOptionSelected(dynamic value) {
    _advanceTimer?.cancel();
    widget.onAnswerChanged(value);
    // Give brief visual feedback so user sees their selection, then auto-transfer to next question
    _advanceTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) {
        widget.onNext();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _textController = TextEditingController(
      text: widget.currentAnswer != null ? widget.currentAnswer.toString() : '',
    );

    _animController.forward();
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _advanceTimer?.cancel();
    if (oldWidget.question.id != widget.question.id) {
      _animController.reset();
      _textController.text =
          widget.currentAnswer != null ? widget.currentAnswer.toString() : '';
      _animController.forward();
    } else if (oldWidget.currentAnswer != widget.currentAnswer) {
      final newText =
          widget.currentAnswer != null ? widget.currentAnswer.toString() : '';
      if (_textController.text != newText) {
        _textController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _animController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleVoiceResult(String spokenText) {
    final clean = spokenText.trim().toLowerCase();

    switch (widget.question.type) {
      case 'number':
        final match = RegExp(r'\d+').firstMatch(clean);
        if (match != null) {
          final numberVal = num.tryParse(match.group(0)!);
          if (numberVal != null) {
            _textController.text = numberVal.toString();
            widget.onAnswerChanged(numberVal);
          }
        }
        break;

      case 'boolean':
        if (clean.contains('yes') ||
            clean.contains('हाँ') ||
            clean.contains('हा') ||
            clean.contains('true') ||
            clean.contains('sahi')) {
          _handleOptionSelected(true);
        } else if (clean.contains('no') ||
            clean.contains('नहीं') ||
            clean.contains('nahi') ||
            clean.contains('false') ||
            clean.contains('galat')) {
          _handleOptionSelected(false);
        }
        break;

      case 'single_choice':
        final options = widget.question.options ?? [];
        for (final opt in options) {
          if (clean.contains(opt.toLowerCase())) {
            _handleOptionSelected(opt);
            return;
          }
        }
        break;

      default:
        _textController.text = spokenText;
        widget.onAnswerChanged(spokenText);
    }
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
      default:
        // Convert camelCase or snake_case to Title Case
        final replaced = option.replaceAll('_', ' ');
        return replaced[0].toUpperCase() + replaced.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider?>();
    final langCode = localeProvider?.languageCode ?? 'en';
    final l10n = SahayLocalizations.of(context);

    final questionText = (langCode == 'hi' &&
            widget.question.labelHindi != null &&
            widget.question.labelHindi!.isNotEmpty)
        ? widget.question.labelHindi!
        : (widget.question.label ?? widget.question.id);

    final bool hasValidAnswer = widget.currentAnswer != null &&
        widget.currentAnswer.toString().trim().isNotEmpty;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepNavy.withValues(alpha: 0.06),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Counter & Optional Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.currentStep != null && widget.totalSteps != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleSage,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Step ${widget.currentStep} of ${widget.totalSteps}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  if (!widget.isMandatory)
                    Text(
                      'Optional',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Question Heading
              Text(
                questionText,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavy,
                  height: 1.35,
                ),
              ),

              // Helper / Explanatory Text
              if (widget.question.helperText != null &&
                  widget.question.helperText!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.question.helperText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Interactive Input Control according to Question Type
              _buildInputControl(context),

              const SizedBox(height: 16),

              // Integrated Voice Input Button
              Center(
                child: VoiceInputButton(
                  onResult: _handleVoiceResult,
                  size: 48,
                  showLabel: true,
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Actions: Next and optional Skip
              ElevatedButton(
                onPressed: (hasValidAnswer || !widget.isMandatory)
                    ? widget.onNext
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indianTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.shimmerBase,
                  disabledForegroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.next,
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),

              if (!widget.isMandatory && widget.onSkip != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    l10n.skip,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputControl(BuildContext context) {
    switch (widget.question.type) {
      case 'boolean':
        return _buildBooleanControl(context);
      case 'single_choice':
        return _buildSingleChoiceControl(context);
      case 'number':
        return _buildNumberControl(context);
      case 'text':
      default:
        return _buildTextControl(context);
    }
  }

  Widget _buildBooleanControl(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final bool? isSelectedYes = widget.currentAnswer == true
        ? true
        : (widget.currentAnswer == false ? false : null);

    return Row(
      children: [
        // Yes Button
        Expanded(
          child: Material(
            color: isSelectedYes == true
                ? AppColors.forestGreen
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleOptionSelected(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelectedYes == true
                        ? AppColors.forestGreen
                        : AppColors.border,
                    width: isSelectedYes == true ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: isSelectedYes == true
                          ? Colors.white
                          : AppColors.deepNavy,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.yes,
                      style: AppTextStyles.label.copyWith(
                        color: isSelectedYes == true
                            ? Colors.white
                            : AppColors.deepNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // No Button
        Expanded(
          child: Material(
            color: isSelectedYes == false
                ? AppColors.mutedCoral
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleOptionSelected(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelectedYes == false
                        ? AppColors.mutedCoral
                        : AppColors.border,
                    width: isSelectedYes == false ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: isSelectedYes == false
                          ? Colors.white
                          : AppColors.deepNavy,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.no,
                      style: AppTextStyles.label.copyWith(
                        color: isSelectedYes == false
                            ? Colors.white
                            : AppColors.deepNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleChoiceControl(BuildContext context) {
    final options = widget.question.options ?? [];

    if (options.length > 5) {
      // For large option sets (e.g. states), use a styled dropdown or wrapped chips
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warmSand.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: options.contains(widget.currentAnswer)
                ? widget.currentAnswer as String
                : null,
            hint: Text(
              'Select an option...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.deepNavy,
            ),
            borderRadius: BorderRadius.circular(16),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  _formatOptionLabel(opt, context),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _handleOptionSelected(val);
              }
            },
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = widget.currentAnswer == option;
        return Material(
          color: isSelected ? AppColors.indianTeal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _handleOptionSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.indianTeal
                      : AppColors.borderLight,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatOptionLabel(option, context),
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? Colors.white : AppColors.deepNavy,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberControl(BuildContext context) {
    final isIncomeQuestion = widget.question.id == 'annualIncome' ||
        widget.question.id == 'annualFamilyIncome';
    final lang = context.watch<LocaleProvider>().languageCode;
    final isHi = lang == 'hi';

    final textField = TextField(
      controller: _textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        if (widget.currentAnswer != null) {
          widget.onNext();
        }
      },
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.deepNavy,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.warmSand.withValues(alpha: 0.35),
        hintText: 'Enter number...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        suffixText: widget.question.unit,
        suffixStyle: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.indianTeal, width: 2),
        ),
      ),
      onChanged: (val) {
        final parsed = num.tryParse(val.trim());
        widget.onAnswerChanged(parsed ?? val.trim());
      },
    );

    if (!isIncomeQuestion) {
      return textField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textField,
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            IncomeEstimationModal.show(
              context,
              onEstimateApplied: (estimate) {
                final intVal = estimate.toInt();
                _textController.text = intVal.toString();
                _handleOptionSelected(intVal);
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paleSage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.forestGreen, size: 16),
                const SizedBox(width: 6),
                Text(
                  isHi
                      ? 'अनुमान नहीं है? आय सहायक से गणना करें'
                      : 'Not sure? Calculate with Income Assistant',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextControl(BuildContext context) {
    return TextField(
      controller: _textController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        if (widget.currentAnswer != null) {
          widget.onNext();
        }
      },
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.deepNavy,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.warmSand.withValues(alpha: 0.35),
        hintText: 'Type your answer...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.indianTeal, width: 2),
        ),
      ),
      onChanged: (val) {
        widget.onAnswerChanged(val.trim());
      },
    );
  }
}
