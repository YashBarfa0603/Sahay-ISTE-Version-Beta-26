import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/l10n/app_localizations.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/eligibility_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/screens/csc_locator_screen.dart';
import 'package:sahay/screens/document_checklist_screen.dart';
import 'package:sahay/screens/my_documents_screen.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/providers/user_document_provider.dart';
import 'package:sahay/services/document_catalogue_service.dart';
import 'package:sahay/services/scheme_notes_service.dart';
import 'package:sahay/services/voice_service.dart';
import 'package:sahay/widgets/confidence_badge.dart';
import 'package:sahay/widgets/expandable_document_card.dart';
import 'package:sahay/widgets/sahay_app_bar.dart';
import 'package:sahay/widgets/scheme_source_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/application/smart_filler_preparation_screen.dart';
import 'package:sahay/services/youtube_tutorial_service.dart';

class SchemeDetailScreen extends StatefulWidget {
  final SchemeModel scheme;
  final EligibilityModel? eligibility;

  const SchemeDetailScreen({
    super.key,
    required this.scheme,
    this.eligibility,
  });

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VoiceService _voiceService;
  final Set<String> _checkedDocuments = {};
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _voiceService = VoiceService();
    _voiceService.initialize();
  }

  @override
  void didUpdateWidget(SchemeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheme.schemeId != widget.scheme.schemeId) {
      _checkedDocuments.clear();
      if (_isSpeaking) {
        _voiceService.stopSpeaking();
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceService.stopSpeaking();
    _voiceService.dispose();
    super.dispose();
  }

  void _toggleReadAloud(String text, String langCode) {
    if (_isSpeaking) {
      _voiceService.stopSpeaking();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      _voiceService.speak(text, locale: langCode).then((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external URL')),
        );
      }
    }
  }

  void _startSahayApplication(BuildContext context) async {
    final appProvider = context.read<ApplicationProvider>();
    final userProfile = context.read<UserProfileProvider>();
    final locale = context.read<LocaleProvider>().languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.softSaffron),
      ),
    );

    await appProvider.startSession(
      scheme: widget.scheme,
      userProfileAnswers: userProfile.answers,
      language: locale,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartFillerPreparationScreen(scheme: widget.scheme),
      ),
    );
  }

  void _shareScheme(BuildContext context) {
    final text = '${widget.scheme.name}\n${widget.scheme.officialSourceUrl}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheme link copied to share: $text'),
        backgroundColor: AppColors.deepNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SahayLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.languageCode;
    final eligibilityProvider = context.watch<EligibilityProvider>();

    // Retrieve active eligibility assessment if provided or from provider cache
    final assessment = widget.eligibility ??
        eligibilityProvider.getResultForScheme(widget.scheme.schemeId);

    final isCentral = widget.scheme.governmentLevel == GovernmentLevel.central;
    final levelBadgeColor = isCentral ? AppColors.softSaffron : AppColors.indianTeal;

    final displayName = (currentLang == 'hi' &&
            widget.scheme.nameHindi != null &&
            widget.scheme.nameHindi!.isNotEmpty)
        ? widget.scheme.nameHindi!
        : widget.scheme.name;

    final displayDescription = (currentLang == 'hi' &&
            widget.scheme.descriptionHindi != null &&
            widget.scheme.descriptionHindi!.isNotEmpty)
        ? widget.scheme.descriptionHindi!
        : widget.scheme.description;

    final displayBenefits = (currentLang == 'hi' &&
            widget.scheme.benefitsHindi != null &&
            widget.scheme.benefitsHindi!.isNotEmpty)
        ? widget.scheme.benefitsHindi!
        : widget.scheme.benefits;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: SahayAppBar(
        title: displayName,
        showBackButton: true,
        showLanguageToggle: true,
        extraActions: [
          // Read Aloud TTS Action Button
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              color: AppColors.softSaffron,
            ),
            tooltip: 'Read Scheme Aloud',
            onPressed: () => _toggleReadAloud(
              '$displayName. $displayDescription. Benefits: $displayBenefits',
              currentLang,
            ),
          ),
          // Share Action Button
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share Scheme',
            onPressed: () => _shareScheme(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Hero Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              color: AppColors.deepNavy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelBadgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCentral ? 'CENTRAL SCHEME' : 'STATE SCHEME',
                          style: AppTextStyles.caption.copyWith(
                            color: isCentral ? AppColors.deepNavy : Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category Pill
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.scheme.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Confidence Badge if assessed
                      if (assessment != null) ...[
                        const SizedBox(width: 8),
                        ConfidenceBadge(result: assessment.result),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scheme Name
                  Text(
                    displayName,
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Ministry
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.softSaffron),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.scheme.ministry,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation TabBar
            Container(
              color: AppColors.warmSand,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.indianTeal,
                indicatorWeight: 3.5,
                labelColor: AppColors.deepNavy,
                unselectedLabelColor: AppColors.deepNavy.withValues(alpha: 0.6),
                labelStyle: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Eligibility'),
                  Tab(text: 'Documents'),
                  Tab(text: 'How to Apply'),
                ],
              ),
            ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Overview Tab
                  _buildOverviewTab(displayDescription, displayBenefits, currentLang),

                  // 2. Eligibility Tab
                  _buildEligibilityTab(assessment, currentLang, l10n),

                  // 3. Documents Tab
                  _buildDocumentsTab(l10n),

                  // 4. How to Apply Tab
                  _buildHowToApplyTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(String description, String benefits, String langCode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scheme Description
          Text(
            'About the Scheme',
            style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.deepNavy),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.deepNavy.withValues(alpha: 0.88),
              height: 1.6,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 22),

          // Benefits Card (Pale Sage Background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paleSage,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.forestGreen.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.forestGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheme Entitlements & Benefits',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.forestGreen,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  benefits,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.deepNavy,
                    height: 1.55,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),

          if (widget.scheme.applicableStates.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Applicable States & Territories',
              style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.scheme.applicableStates.map((state) {
                return Chip(
                  backgroundColor: AppColors.warmSand,
                  label: Text(state, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // Phase 5: Dedicated Edge Cases & Important Precautions Section
          _buildEdgeCasesAndPrecautionsSection(langCode),

          const SizedBox(height: 24),

          // Official Scheme Source Info Footer
          SchemeSourceInfo(scheme: widget.scheme),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEligibilityTab(
    EligibilityModel? assessment,
    String langCode,
    SahayLocalizations l10n,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assessment != null) ...[
            // Overall Assessment Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusBg(assessment.result),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _getStatusBorder(assessment.result)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(assessment.result), color: _getStatusBorder(assessment.result), size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(assessment.result),
                          style: AppTextStyles.heading3.copyWith(
                            color: _getStatusBorder(assessment.result),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assessment.explanation,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.deepNavy,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Prompt to take assessment if not yet completed
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warmSand,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.softSaffron),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eligibility Not Checked Yet',
                    style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.deepNavy),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Take a quick 2-minute eligibility check to evaluate whether your profile fulfills all required criteria.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indianTeal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check My Eligibility'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (assessment != null && assessment.conditionResults.isNotEmpty) ...[
            // 1. Failed Mandatory Conditions (Why you do not qualify)
            if (assessment.conditionResults.any((c) => c.status == ConditionStatus.failed && c.isMandatory)) ...[
              Text(
                '✕ Conditions Not Satisfied',
                style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.mutedCoral),
              ),
              const SizedBox(height: 8),
              ...assessment.conditionResults
                  .where((c) => c.status == ConditionStatus.failed && c.isMandatory)
                  .map((condition) => _ConditionResultCard(condition: condition)),
              const SizedBox(height: 16),
            ],

            // 2. Satisfied Mandatory Conditions (Why you may qualify)
            if (assessment.conditionResults.any((c) => c.status == ConditionStatus.passed && c.isMandatory)) ...[
              Text(
                '✓ Conditions Satisfied',
                style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 8),
              ...assessment.conditionResults
                  .where((c) => c.status == ConditionStatus.passed && c.isMandatory)
                  .map((condition) => _ConditionResultCard(condition: condition)),
              const SizedBox(height: 16),
            ],

            // 3. Missing Information
            if (assessment.conditionResults.any((c) => c.status == ConditionStatus.pending)) ...[
              Text(
                '? Additional Information Required',
                style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.steelBlue),
              ),
              const SizedBox(height: 8),
              ...assessment.conditionResults
                  .where((c) => c.status == ConditionStatus.pending)
                  .map((condition) => _ConditionResultCard(condition: condition)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Provide Missing Information'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.steelBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Optional Conditions
            if (assessment.conditionResults.any((c) => !c.isMandatory)) ...[
              Text(
                'Optional Priorities & Criteria',
                style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 8),
              ...assessment.conditionResults
                  .where((c) => !c.isMandatory)
                  .map((condition) => _ConditionResultCard(condition: condition)),
              const SizedBox(height: 16),
            ],
          ] else ...[
            Text(
              'Official Eligibility Criteria',
              style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),
            ...widget.scheme.eligibilityRules.map((rule) {
              return _GenericRuleCard(rule: rule);
            }),
          ],

          if (assessment != null && assessment.missingInformation.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.steelBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Missing information required: ${assessment.missingInformation.join(", ")}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Edge Cases & Important Precautions Section
          _buildEdgeCasesAndPrecautionsSection(langCode),

          const SizedBox(height: 24),
          SchemeSourceInfo(scheme: widget.scheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEdgeCasesAndPrecautionsSection(String currentLang) {
    final notes = SchemeNotesService.getNotesForSchemeOrGrounded(widget.scheme);
    final l10n = SahayLocalizations.of(context);
    final isHi = currentLang == 'hi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.softSaffron.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 20,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.edgeCasesPrecautions,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 17,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isHi
              ? 'आधिकारिक अपवर्जन नियम, पात्रता शर्तें एवं आवेदन सावधानियां:'
              : 'Authoritative disqualifications, grounded conditions, and application safeguards:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.deepNavy.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 16),

        // 1. Critical Eligibility Conditions
        _buildNotesCard(
          title: isHi ? 'अनिवार्य पात्रता शर्तें' : 'Critical Eligibility Conditions',
          items: isHi ? notes.criticalConditionsHindi : notes.criticalConditions,
          icon: Icons.verified_outlined,
          borderColor: AppColors.indianTeal,
          headerColor: AppColors.indianTeal,
          bulletIcon: Icons.check_circle_outline_rounded,
          bulletColor: AppColors.forestGreen,
        ),
        const SizedBox(height: 12),

        // 2. Reasons Leading to Disqualification
        _buildNotesCard(
          title: isHi ? 'अपात्रता एवं अस्वीकृति के कारण' : 'Reasons Leading to Disqualification',
          items: isHi ? notes.disqualificationReasonsHindi : notes.disqualificationReasons,
          icon: Icons.warning_amber_rounded,
          borderColor: AppColors.mutedCoral,
          headerColor: AppColors.mutedCoral,
          bulletIcon: Icons.cancel_outlined,
          bulletColor: AppColors.mutedCoral,
        ),
        const SizedBox(height: 12),

        // 3. Important Document Requirements
        _buildNotesCard(
          title: isHi ? 'महत्वपूर्ण दस्तावेज आवश्यकताएं' : 'Important Document Requirements',
          items: isHi ? notes.documentRequirementsHindi : notes.documentRequirements,
          icon: Icons.assignment_outlined,
          borderColor: AppColors.steelBlue,
          headerColor: AppColors.steelBlue,
          bulletIcon: Icons.description_outlined,
          bulletColor: AppColors.steelBlue,
        ),
        const SizedBox(height: 12),

        // 4. Application Precautions
        _buildNotesCard(
          title: isHi ? 'आवेदन करते समय सावधानियां' : 'Application Precautions',
          items: isHi ? notes.applicationPrecautionsHindi : notes.applicationPrecautions,
          icon: Icons.shield_outlined,
          borderColor: AppColors.softSaffron,
          headerColor: const Color(0xFFC77800),
          bulletIcon: Icons.info_outline_rounded,
          bulletColor: const Color(0xFFC77800),
        ),
      ],
    );
  }

  Widget _buildNotesCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color borderColor,
    required Color headerColor,
    required IconData bulletIcon,
    required Color bulletColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(icon, color: headerColor, size: 22),
            title: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
                fontSize: 14.5,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(bulletIcon, size: 16, color: bulletColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.deepNavy.withValues(alpha: 0.9),
                          height: 1.45,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsTab(SahayLocalizations l10n) {
    final docs = widget.scheme.requiredDocuments;
    final userDocProvider = context.watch<UserDocumentProvider>();
    final currentLang = l10n.locale.languageCode;
    final isHi = currentLang == 'hi';

    // Count how many required docs are currently present in user's vault
    int vaultMatchedCount = 0;
    for (final docName in docs) {
      final canonicalId = DocumentCatalogueService.matchCanonicalId(docName);
      if (userDocProvider.hasDocument(canonicalId)) {
        vaultMatchedCount++;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.checklistTitle,
                  style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.deepNavy),
                ),
              ),
              Text(
                '${_checkedDocuments.length}/${docs.length} ${isHi ? "तैयार" : "Ready"}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.indianTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isHi
                ? 'आवेदन से पूर्व अपने पास उपलब्ध दस्तावेजों की जांच करें और विवरण देखने के लिए कार्ड पर टैप करें:'
                : 'Check off certificates you have ready in hand. Tap any document card to view guidelines and specimen.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.deepNavy.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),

          // Vault Matching Summary Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleSage,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.forestGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isHi
                            ? 'निजी वॉल्ट स्थिति: $vaultMatchedCount/${docs.length} दस्तावेज़ वॉल्ट में उपलब्ध'
                            : 'Personal Vault Match: $vaultMatchedCount/${docs.length} documents in vault',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.viewInVault,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isHi
                      ? 'स्पष्टीकरण: वॉल्ट में अपलोड पूरी तरह से वैकल्पिक है। सरकारी अधिकारी मूल प्रमाणपत्रों का ही आधिकारिक सत्यापन करेंगे।'
                      : 'Notice: Upload to vault is 100% optional. Government authorities verify physical/portal certificates during official processing.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepNavy.withValues(alpha: 0.75),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (docs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleSage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isHi
                    ? 'मानक आधार सत्यापन के अतिरिक्त कोई विशेष दस्तावेज अनिवार्य नहीं है।'
                    : 'No specialized documents mandated beyond standard Aadhaar KYC.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
              ),
            )
          else
            ...docs.map((docName) {
              final isChecked = _checkedDocuments.contains(docName);
              final canonicalId = DocumentCatalogueService.matchCanonicalId(docName);
              final uploadedDoc = userDocProvider.getDocument(canonicalId);

              return ExpandableDocumentCard(
                documentTitle: docName,
                isChecked: isChecked,
                uploadedDoc: uploadedDoc,
                language: currentLang,
                onChecked: (val) {
                  setState(() {
                    if (val == true) {
                      _checkedDocuments.add(docName);
                    } else {
                      _checkedDocuments.remove(docName);
                    }
                  });
                },
                onUploadPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyDocumentsScreen(preselectedType: canonicalId),
                    ),
                  );
                },
                onViewInVaultPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
                  );
                },
              );
            }),

          const SizedBox(height: 24),

          // Download as PDF Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentChecklistScreen(singleScheme: widget.scheme),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: Text(
                l10n.downloadPdfChecklist,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indianTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SchemeSourceInfo(scheme: widget.scheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHowToApplyTab(SahayLocalizations l10n) {
    LocaleProvider? loc;
    try {
      loc = Provider.of<LocaleProvider>(context);
    } catch (_) {
      loc = null;
    }
    final currentLang = loc?.languageCode ?? 'en';

    final hasOnlineUrl = widget.scheme.applicationUrl != null &&
        widget.scheme.applicationUrl!.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Procedure',
            style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.deepNavy),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.warmSand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.scheme.applicationProcess,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.deepNavy,
                height: 1.6,
                fontSize: 14.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ------------------------------------
          // PROMINENT PRIMARY ACTION: APPLY WITH SAHAY (10-Scheme Smart Application Filler)
          // ------------------------------------
          Builder(builder: (ctx) {
            ApplicationProvider? appProvider;
            try {
              appProvider = Provider.of<ApplicationProvider>(ctx);
            } catch (_) {
              appProvider = null;
            }
            if (appProvider?.isSchemeSupported(widget.scheme.schemeId) != true) {
              return const SizedBox.shrink();
            }
            return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepNavy, Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepNavy.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.softSaffron,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.deepNavy, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply with SAHAY',
                            style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            'AI-Powered Application Assistant',
                            style: AppTextStyles.caption.copyWith(color: AppColors.softSaffron, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Let SAHAY help you complete this application using your profile and documents.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.4, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _startSahayApplication(context),
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.deepNavy),
                    label: const Text(
                      'Start Application with SAHAY',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softSaffron,
                      foregroundColor: AppColors.deepNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
          }),
          const SizedBox(height: 18),

          if (hasOnlineUrl) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(widget.scheme.applicationUrl!),
                icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                label: const Text(
                  'Apply Online (Official Portal)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indianTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // YouTube Application Tutorial Video Guide
          _buildYouTubeTutorialSection(context, currentLang),

          // Offline apply notice and CSC locator shortcut
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleSage,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_center_outlined, color: AppColors.forestGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Citizens without internet connectivity can visit their nearest Common Service Centre (CSC) or Gram Panchayat office.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, height: 1.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CscLocatorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.storefront_rounded, size: 16, color: AppColors.forestGreen),
                    label: const Text(
                      'Find Nearest CSC / Jan Seva Kendra',
                      style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.forestGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Verification notice if unverified or under verification
          if (widget.scheme.status == SchemeStatus.underVerification ||
              widget.scheme.verificationStatus == VerificationStatus.pending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softSaffron.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.softSaffron),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.deepNavy, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notice: This scheme is newly discovered and currently undergoing departmental verification. Verify official notifications before submitting personal records.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.deepNavy, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SchemeSourceInfo(scheme: widget.scheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildYouTubeTutorialSection(BuildContext context, String currentLang) {
    final isHi = currentLang == 'hi';
    final tutorial = YouTubeTutorialService.getTutorialForScheme(widget.scheme.schemeId);

    if (tutorial == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.steelBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off_outlined, color: AppColors.steelBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi
                        ? 'इस योजना के लिए वर्तमान में कोई सत्यापित आवेदन ट्यूटोरियल उपलब्ध नहीं है।'
                        : 'No verified application tutorial is currently available for this scheme.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHi
                        ? 'हम नागरिकों की सुरक्षा हेतु केवल आधिकारिक एवं सत्यापित सरकारी वीडियो गाइड ही लिंक करते हैं।'
                        : 'SAHAY only references verified official tutorials to prevent fraudulent guidance.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final title = isHi ? tutorial.videoTitleHindi : tutorial.videoTitle;
    final desc = isHi ? tutorial.descriptionHindi : tutorial.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isHi ? 'वीडियो गाइड — आवेदन कैसे करें' : 'Video Tutorial — How to Apply',
                    style: AppTextStyles.heading3.copyWith(fontSize: 15, color: AppColors.deepNavy),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 12, color: AppColors.forestGreen),
                      SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Thumbnail Card
          InkWell(
            onTap: () => _launchUrl(tutorial.youtubeUrl),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.network(
                    tutorial.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.deepNavy,
                      child: const Center(
                        child: Icon(Icons.video_library_rounded, size: 48, color: Colors.white54),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  // Play button badge
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Duration badge in bottom corner
                  if (tutorial.duration != null)
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tutorial.duration!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Video Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.steelBlue),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        tutorial.channelName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.steelBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.paleSage,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tutorial.language,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.75),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(tutorial.youtubeUrl),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: Text(
                      isHi ? 'YouTube पर पूरा वीडियो देखें' : 'Watch Step-by-Step on YouTube',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBg(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return AppColors.forestGreen.withValues(alpha: 0.12);
      case EligibilityResult.needsMoreInformation:
        return AppColors.steelBlue.withValues(alpha: 0.12);
      case EligibilityResult.doesNotQualify:
        return AppColors.mutedCoral.withValues(alpha: 0.12);
    }
  }

  Color _getStatusBorder(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return AppColors.forestGreen;
      case EligibilityResult.needsMoreInformation:
        return AppColors.steelBlue;
      case EligibilityResult.doesNotQualify:
        return AppColors.mutedCoral;
    }
  }

  IconData _getStatusIcon(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return Icons.check_circle_rounded;
      case EligibilityResult.needsMoreInformation:
        return Icons.help_outline_rounded;
      case EligibilityResult.doesNotQualify:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusTitle(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return 'You May Qualify for this Scheme';
      case EligibilityResult.needsMoreInformation:
        return 'Additional Information Needed';
      case EligibilityResult.doesNotQualify:
        return 'Currently Not Eligible';
    }
  }
}

class _ConditionResultCard extends StatelessWidget {
  final EligibilityConditionResult condition;

  const _ConditionResultCard({required this.condition});

  @override
  Widget build(BuildContext context) {
    final IconData statusIcon;
    final Color statusColor;

    switch (condition.status) {
      case ConditionStatus.passed:
        statusIcon = Icons.check_circle_rounded;
        statusColor = AppColors.forestGreen;
        break;
      case ConditionStatus.failed:
        statusIcon = Icons.cancel_rounded;
        statusColor = AppColors.mutedCoral;
        break;
      case ConditionStatus.pending:
        statusIcon = Icons.help_outline_rounded;
        statusColor = AppColors.steelBlue;
        break;
    }

    final displayLabel = (condition.label != null && condition.label!.isNotEmpty)
        ? condition.label!
        : condition.field.replaceAll('_', ' ').toUpperCase();

    final requiredText = condition.requiredDescription ??
        (condition.expectedValue != null ? 'Requirement: ${condition.expectedValue}' : condition.condition);

    final userValueText = condition.formattedUserValue ??
        (condition.actualValue != null ? condition.actualValue.toString() : 'Not Provided');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Label & Mandatory / Borderline pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayLabel.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (condition.isBorderline)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Text(
                          'BORDERLINE',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.amber.shade900,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: condition.isMandatory
                            ? AppColors.softSaffron.withValues(alpha: 0.3)
                            : AppColors.steelBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        condition.isMandatory ? 'MANDATORY' : 'OPTIONAL',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepNavy,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Understandable Reason / Explanation
                if (condition.explanation != null)
                  Text(
                    condition.explanation!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.deepNavy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),

                const SizedBox(height: 8),

                // Comparison Box: Required vs User Value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Required:', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              requiredText,
                              textAlign: TextAlign.end,
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Profile:', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userValueText,
                              textAlign: TextAlign.end,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (condition.differenceDescription != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Difference:', style: AppTextStyles.caption.copyWith(color: AppColors.mutedCoral)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                condition.differenceDescription!,
                                textAlign: TextAlign.end,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedCoral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Verifying Document & Verification Status
                if (condition.verifyingDocument != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: AppColors.steelBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Verifying Document: ${condition.verifyingDocument!}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.steelBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.warmSand,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          condition.verificationStatus == 'document_verified'
                              ? 'Verified'
                              : 'Self-Reported',
                          style: AppTextStyles.caption.copyWith(
                            color: condition.verificationStatus == 'document_verified'
                                ? AppColors.forestGreen
                                : AppColors.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericRuleCard extends StatelessWidget {
  final EligibilityRule rule;

  const _GenericRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.rule_rounded, color: AppColors.indianTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.field.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.description ?? '${rule.field} must satisfy criteria (${rule.operator.name} ${rule.value})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.deepNavy,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
