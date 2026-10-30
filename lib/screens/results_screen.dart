import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/scheme_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/document_checklist_screen.dart';
import 'package:sahay/screens/home_screen.dart';
import 'package:sahay/screens/scheme_detail_screen.dart';
import 'package:sahay/services/voice_service.dart';
import 'package:sahay/widgets/eligibility_card.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedFilterIndex = 0; // 0: May Qualify, 1: More Info, 2: All
  late final VoiceService _voiceService;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _voiceService.initialize();
  }

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _voiceService.dispose();
    super.dispose();
  }

  void _readResultsAloud(
    int qualifyingCount,
    int needsInfoCount,
    int notQualifyingCount,
    String langCode,
  ) {
    if (_isSpeaking) {
      _voiceService.stopSpeaking();
      setState(() => _isSpeaking = false);
      return;
    }

    final String speechText;
    if (langCode == 'hi') {
      speechText =
          'आपकी पात्रता जांच के परिणाम: आप $qualifyingCount योजनाओं के लिए पात्र हो सकते हैं। $needsInfoCount योजनाओं के लिए और जानकारी आवश्यक है। $notQualifyingCount योजनाओं के लिए आप पात्र नहीं हैं।';
    } else {
      speechText =
          'Assessment results: You may qualify for $qualifyingCount schemes. $needsInfoCount schemes require more information. You are currently not eligible for $notQualifyingCount schemes.';
    }

    setState(() => _isSpeaking = true);
    _voiceService.speak(speechText, locale: langCode).then((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _confirmStartOver(BuildContext context, SahayLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Start Over / पुनः आरंभ करें',
          style: AppTextStyles.heading3.copyWith(color: AppColors.deepNavy),
        ),
        content: Text(
          l10n.clearDataConfirm.isNotEmpty && l10n.clearDataConfirm != 'clearDataConfirm'
              ? l10n.clearDataConfirm
              : 'Are you sure you want to clear your current answers and start a new assessment?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel.isNotEmpty && l10n.cancel != 'cancel' ? l10n.cancel : 'Cancel',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UserProfileProvider>().clearAllAnswers();
              context.read<EligibilityProvider>().clearResults();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedCoral,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.confirm.isNotEmpty && l10n.confirm != 'confirm' ? l10n.confirm : 'Clear & Reset',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final eligibilityProvider = context.watch<EligibilityProvider>();
    final schemeProvider = context.watch<SchemeProvider>();

    final qualifyingSchemes = eligibilityProvider.qualifyingSchemes;
    final needsInfoSchemes = eligibilityProvider.needsInfoSchemes;
    final notQualifyingSchemes = eligibilityProvider.notQualifyingSchemes;

    // Filter displayed schemes based on segmented filter index
    final List<EligibilityModel> displayedAssessments;
    switch (_selectedFilterIndex) {
      case 0:
        displayedAssessments = qualifyingSchemes;
        break;
      case 1:
        displayedAssessments = needsInfoSchemes;
        break;
      default:
        displayedAssessments = [
          ...qualifyingSchemes,
          ...needsInfoSchemes,
          ...notQualifyingSchemes,
        ];
        break;
    }

    final schemeMap = {for (final s in schemeProvider.schemes) s.schemeId: s};

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: currentLang == 'hi' ? 'पात्रता परिणाम' : 'Assessment Results',
        showBackButton: true,
        showLanguageToggle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Metric Cards Container
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.paleSage,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.indianTeal.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentLang == 'hi' ? 'पात्रता सारांश' : 'Eligibility Summary',
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 16,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          // Read Results Aloud TTS Button
                          TextButton.icon(
                            onPressed: () => _readResultsAloud(
                              qualifyingSchemes.length,
                              needsInfoSchemes.length,
                              notQualifyingSchemes.length,
                              currentLang,
                            ),
                            icon: Icon(
                              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                              size: 18,
                              color: AppColors.indianTeal,
                            ),
                            label: Text(
                              _isSpeaking ? 'Stop' : 'Read Aloud',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.indianTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3 Summary Columns (Qualify / More Info / Not Eligible)
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryStatBadge(
                              count: qualifyingSchemes.length,
                              label: l10n.mayQualify,
                              color: AppColors.forestGreen,
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryStatBadge(
                              count: needsInfoSchemes.length,
                              label: l10n.needsMoreInfo,
                              color: AppColors.steelBlue,
                              icon: Icons.help_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryStatBadge(
                              count: notQualifyingSchemes.length,
                              label: l10n.doesNotQualify,
                              color: AppColors.mutedCoral,
                              icon: Icons.cancel_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Segmented Tab Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.warmSand,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildSegment(
                        0,
                        '${l10n.mayQualify} (${qualifyingSchemes.length})',
                        AppColors.forestGreen,
                      ),
                      _buildSegment(
                        1,
                        '${l10n.needsMoreInfo} (${needsInfoSchemes.length})',
                        AppColors.steelBlue,
                      ),
                      _buildSegment(
                        2,
                        'All (${eligibilityProvider.totalEvaluatedCount})',
                        AppColors.deepNavy,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Results List of Eligibility Cards
              if (displayedAssessments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No schemes currently matching this filter status.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedAssessments.length,
                  itemBuilder: (context, index) {
                    final assessment = displayedAssessments[index];
                    final scheme = schemeMap[assessment.schemeId] ??
                        SchemeModel(
                          schemeId: assessment.schemeId,
                          name: assessment.schemeId,
                          description: assessment.explanation,
                          category: 'general',
                          ministry: 'Government Authority',
                          governmentLevel: GovernmentLevel.central,
                          benefits: '',
                          applicationProcess: '',
                          officialSourceUrl: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                    return EligibilityCard(
                      scheme: scheme,
                      eligibility: assessment,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SchemeDetailScreen(
                              scheme: scheme,
                              eligibility: assessment,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Bottom Actions: Download Checklist & Start Over
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Download Checklist Button (Indian Teal)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DocumentChecklistScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                        label: Text(
                          l10n.downloadChecklist.isNotEmpty && l10n.downloadChecklist != 'downloadChecklist'
                              ? l10n.downloadChecklist
                              : 'Download Document Checklist (PDF)',
                          style: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indianTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Start Over Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmStartOver(context, l10n),
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.deepNavy),
                        label: Text(
                          'Start Over (Clear Session)',
                          style: AppTextStyles.label.copyWith(color: AppColors.deepNavy),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Privacy Notice Banner at Bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paleSage,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppColors.steelBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.sessionNotice.isNotEmpty && l10n.sessionNotice != 'sessionNotice'
                              ? l10n.sessionNotice
                              : 'Your data is stored only in this session memory and never shared or tracked.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepNavy,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(int index, String title, Color activeColor) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? activeColor : AppColors.deepNavy.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryStatBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.deepNavy,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
