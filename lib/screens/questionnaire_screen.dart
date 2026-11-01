import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/auth_provider.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/results_screen.dart';
import 'package:sahay/services/question_engine.dart';
import 'package:sahay/services/scheme_data_service.dart';
import 'package:sahay/widgets/question_card.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String? targetSchemeId;

  const QuestionnaireScreen({
    super.key,
    this.targetSchemeId,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final QuestionEngine _questionEngine = const QuestionEngine();
  final List<QuestionItem> _questionHistory = [];

  QuestionItem? _currentQuestion;
  dynamic _currentAnswer;
  bool _isEvaluating = false;
  bool _slideForward = true;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQuestionnaire();
    });
  }

  Future<void> _initQuestionnaire() async {
    final schemeProvider = context.read<SchemeProvider>();
    if (schemeProvider.schemes.isEmpty && !schemeProvider.isLoading) {
      await schemeProvider.loadSchemes(SchemeDataService());
    }
    if (!mounted) return;

    final userProfile = context.read<UserProfileProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.currentUser != null) {
      userProfile.populateFromUser(auth.currentUser!);
    }
    final schemes = (widget.targetSchemeId != null &&
            schemeProvider.schemes.any((s) => s.schemeId == widget.targetSchemeId))
        ? schemeProvider.schemes.where((s) => s.schemeId == widget.targetSchemeId).toList()
        : schemeProvider.schemes;

    // Pick first question from engine based on existing answers
    final next = _questionEngine.getNextQuestion(userProfile.answers, schemes);
    if (next == null && userProfile.hasAnswers) {
      await _evaluateAndFinish();
      return;
    }

    final initialQuestion = next ?? _questionEngine.allQuestions.first;

    setState(() {
      _currentQuestion = initialQuestion;
      _currentAnswer = userProfile.getAnswer(initialQuestion.id);
    });
  }

  void _onAnswerChanged(dynamic answer) {
    setState(() {
      _currentAnswer = answer;
    });
    if (_currentQuestion != null) {
      context.read<UserProfileProvider>().setAnswer(_currentQuestion!.id, answer);
    }
  }

  void _onNext() {
    if (_currentQuestion == null || _isEvaluating || _isTransitioning) return;
    _isTransitioning = true;
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) _isTransitioning = false;
    });

    final userProfile = context.read<UserProfileProvider>();
    final schemeProvider = context.read<SchemeProvider>();

    // Persist current answer
    if (_currentAnswer != null) {
      userProfile.setAnswer(_currentQuestion!.id, _currentAnswer);
    }

    final schemes = (widget.targetSchemeId != null &&
            schemeProvider.schemes.any((s) => s.schemeId == widget.targetSchemeId))
        ? schemeProvider.schemes.where((s) => s.schemeId == widget.targetSchemeId).toList()
        : schemeProvider.schemes;
    final nextQuestion = _questionEngine.getNextQuestion(
      userProfile.answers,
      schemes,
    );

    if (nextQuestion == null || _questionHistory.any((q) => q.id == nextQuestion.id)) {
      // No more impactful questions needed or all relevant schemes determined
      _evaluateAndFinish();
    } else {
      setState(() {
        _slideForward = true;
        _questionHistory.add(_currentQuestion!);
        _currentQuestion = nextQuestion;
        _currentAnswer = userProfile.getAnswer(nextQuestion.id);
      });
    }
  }

  void _onSkip() {
    if (_currentQuestion == null) return;

    final userProfile = context.read<UserProfileProvider>();
    final schemeProvider = context.read<SchemeProvider>();

    final schemes = (widget.targetSchemeId != null &&
            schemeProvider.schemes.any((s) => s.schemeId == widget.targetSchemeId))
        ? schemeProvider.schemes.where((s) => s.schemeId == widget.targetSchemeId).toList()
        : schemeProvider.schemes;
    final nextQuestion = _questionEngine.getNextQuestion(
      userProfile.answers,
      schemes,
    );

    if (nextQuestion == null || _questionHistory.any((q) => q.id == nextQuestion.id)) {
      _evaluateAndFinish();
    } else {
      setState(() {
        _slideForward = true;
        _questionHistory.add(_currentQuestion!);
        _currentQuestion = nextQuestion;
        _currentAnswer = userProfile.getAnswer(nextQuestion.id);
      });
    }
  }

  void _onBack() {
    if (_questionHistory.isNotEmpty) {
      final prevQuestion = _questionHistory.removeLast();
      final userProfile = context.read<UserProfileProvider>();

      setState(() {
        _slideForward = false;
        _currentQuestion = prevQuestion;
        _currentAnswer = userProfile.getAnswer(prevQuestion.id);
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _evaluateAndFinish() async {
    setState(() => _isEvaluating = true);

    final userProfile = context.read<UserProfileProvider>();
    final schemeProvider = context.read<SchemeProvider>();
    final eligibilityProvider = context.read<EligibilityProvider>();

    List<SchemeModel> schemes = schemeProvider.schemes;
    if (schemes.isEmpty) {
      await schemeProvider.loadSchemes(SchemeDataService());
      if (!mounted) return;
      schemes = schemeProvider.schemes;
    }

    // Run eligibility engine evaluation for all schemes
    eligibilityProvider.evaluateAll(schemes, userProfile.answers);

    // Persist answers permanently for authenticated users and mark onboarding completed
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      final answers = Map<String, dynamic>.from(userProfile.answers);
      answers['profileComplete'] = true;
      answers['onboardingCompleted'] = true;
      answers['onboardingCompletedAt'] = DateTime.now().toIso8601String();
      try {
        await auth.updateProfile(answers);
      } catch (e) {
        debugPrint('QuestionnaireScreen: non-fatal updateProfile error: $e');
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;

    final currentStep = _questionHistory.length + 1;
    // Estimated max steps for display progress bar
    final totalSteps = (_questionHistory.length + 5).clamp(8, 16);
    final progress = (currentStep / totalSteps).clamp(0.08, 1.0);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: l10n.eligibilityCheck,
        showBackButton: true,
        onBack: _onBack,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: _isEvaluating
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.indianTeal),
                    const SizedBox(height: 20),
                    Text(
                      currentLang == 'hi'
                          ? 'आपकी पात्रता का मूल्यांकन किया जा रहा है...'
                          : 'Evaluating scheme eligibility for your profile...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _currentQuestion == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.indianTeal),
                  )
                : Column(
                    children: [
                      // Progress Bar Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentLang == 'hi'
                                      ? 'प्रश्न $currentStep'
                                      : 'Question $currentStep',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.indianTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}% Completed',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.deepNavy.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: AppColors.border.withValues(alpha: 0.5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.indianTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated QuestionCard Container
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            transitionBuilder: (child, animation) {
                              final offsetBegin = _slideForward
                                  ? const Offset(0.3, 0.0)
                                  : const Offset(-0.3, 0.0);
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: offsetBegin,
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<String>(_currentQuestion!.id),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: QuestionCard(
                                  question: _currentQuestion!,
                                  currentAnswer: _currentAnswer,
                                  onAnswerChanged: _onAnswerChanged,
                                  onNext: _onNext,
                                  onSkip: _onSkip,
                                  isMandatory: !_currentQuestion!.isConditional,
                                  currentStep: currentStep,
                                  totalSteps: totalSteps,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Navigation Buttons (Back, Skip, Next / Check Eligibility)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        decoration: BoxDecoration(
                          color: AppColors.warmIvory,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, -3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Back Button
                            if (_questionHistory.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: _onBack,
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    l10n.back.isNotEmpty && l10n.back != 'back' ? l10n.back : 'Back',
                                    style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),

                            const Spacer(),

                            // Skip Button (optional question)
                            if (_currentQuestion!.isConditional)
                              TextButton(
                                onPressed: _onSkip,
                                child: Text(
                                  l10n.skip.isNotEmpty && l10n.skip != 'skip' ? l10n.skip : 'Skip',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),

                            const SizedBox(width: 8),

                            // Next or Finish Button
                            ElevatedButton(
                              onPressed: _onNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indianTeal,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.next.isNotEmpty && l10n.next != 'next' ? l10n.next : 'Next',
                                      style: AppTextStyles.buttonText.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
