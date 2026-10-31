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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.scheme.category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Confidence Badge if assessed
                      if (assessment != null)
                        ConfidenceBadge(result: assessment.result),
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
                    Text(
                      'Scheme Entitlements & Benefits',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.forestGreen,
                        fontSize: 16,
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

          Text(
            'Rule-by-Rule Breakdown',
            style: AppTextStyles.heading3.copyWith(fontSize: 17, color: AppColors.deepNavy),
          ),
          const SizedBox(height: 12),

          // Condition Results (if assessed) or Eligibility Rules
          if (assessment != null && assessment.conditionResults.isNotEmpty) ...[
            ...assessment.conditionResults.map((condition) {
              return _ConditionResultCard(condition: condition);
            }),
          ] else ...[
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

          // Phase 5: Important Notes & Grounded Official Eligibility Conditions
          _buildImportantNotesSection(langCode),

          const SizedBox(height: 24),
          SchemeSourceInfo(scheme: widget.scheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImportantNotesSection(String currentLang) {
    final notes = SchemeNotesService.getNotesForScheme(widget.scheme.schemeId);
    if (notes == null) return const SizedBox.shrink();

    final isHi = currentLang == 'hi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.softSaffron.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rule_folder_outlined,
                size: 20,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isHi ? 'महत्वपूर्ण नियम एवं पात्रता शर्तें' : 'Important Notes & Eligibility Conditions',
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
              ? 'आधिकारिक सरकारी दिशानिर्देशों के अनुसार आवश्यक शर्तें व अपात्रता नियम:'
              : 'Authoritative rules and disqualification criteria per official scheme guidelines:',
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
    );
  }

  Widget _buildDocumentsTab(SahayLocalizations l10n) {
    final docs = widget.scheme.requiredDocuments;
    final userDocProvider = context.watch<UserDocumentProvider>();
    final isHi = context.watch<LocaleProvider>().languageCode == 'hi';

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
                  isHi ? 'आवश्यक दस्तावेज चेकलिस्ट' : 'Required Documents Checklist',
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
                        isHi ? 'वॉल्ट खोलें' : 'Open Vault',
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
              child: const Text('No specialized documents mandated beyond standard Aadhaar KYC.'),
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
                language: isHi ? 'hi' : 'en',
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
                    MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
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
                isHi ? 'चेकलिस्ट पीडीएफ डाउनलोड करें' : 'Download Checklist as PDF',
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
            const SizedBox(height: 12),
          ],

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        condition.field.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (condition.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softSaffron.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MANDATORY',
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
                Text(
                  condition.condition,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                if (condition.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    condition.explanation!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.deepNavy.withValues(alpha: 0.75),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (condition.expectedValue != null)
                      Text(
                        'Target: ${condition.expectedValue}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    if (condition.actualValue != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Your value: ${condition.actualValue}',
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
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
