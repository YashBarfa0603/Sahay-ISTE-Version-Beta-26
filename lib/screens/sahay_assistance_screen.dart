import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/core/theme/app_text_styles.dart';
import 'package:sahay/models/chatbot_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/chatbot_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/application/smart_filler_preparation_screen.dart';
import 'package:sahay/screens/my_documents_screen.dart';
import 'package:sahay/screens/questionnaire_screen.dart';
import 'package:sahay/screens/schemes_screen.dart';
import 'package:sahay/services/scheme_data_service.dart';

class SahayAssistanceScreen extends StatefulWidget {
  final String currentScreen;
  final String? selectedSchemeId;
  final String? selectedSchemeName;

  const SahayAssistanceScreen({
    super.key,
    this.currentScreen = 'home',
    this.selectedSchemeId,
    this.selectedSchemeName,
  });

  @override
  State<SahayAssistanceScreen> createState() => _SahayAssistanceScreenState();
}

class _SahayAssistanceScreenState extends State<SahayAssistanceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LocaleProvider>().languageCode;
      context.read<ChatbotProvider>().setContext(
            screen: widget.currentScreen,
            schemeId: widget.selectedSchemeId,
            schemeName: widget.selectedSchemeName,
            language: lang,
          );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _inputController.text;
    if (text.trim().isEmpty) return;

    final lang = context.read<LocaleProvider>().languageCode;
    context.read<ChatbotProvider>().sendUserMessage(text, language: lang);
    _inputController.clear();
    _scrollToBottom();
  }

  /// Validates and executes verified client navigation actions.
  Future<void> _handleNavigationAction(NavigationActionModel action) async {
    final lang = context.read<LocaleProvider>().languageCode;
    final isHi = lang.startsWith('hi');

    if (action.action == 'start_fill_with_sahay' && action.schemeId != null) {
      final schemeId = action.schemeId!;
      SchemeModel? scheme = await SchemeDataService().getSchemeById(schemeId);

      // Fallback: look up in catalogue or build model
      if (scheme == null) {
        final complete = await SchemeDataService().getCompleteCatalogue();
        try {
          scheme = complete.firstWhere((s) =>
              s.schemeId == schemeId ||
              ApplicationProvider.normalizeSchemeId(s.schemeId) ==
                  ApplicationProvider.normalizeSchemeId(schemeId));
        } catch (_) {
          scheme = null;
        }
      }

      if (scheme == null) {
        // Create runtime model for verified scheme
        final now = DateTime.now();
        scheme = SchemeModel(
          schemeId: schemeId,
          name: action.schemeName ?? schemeId,
          description: 'Official Welfare Scheme',
          category: 'Welfare',
          ministry: 'Government of India',
          governmentLevel: GovernmentLevel.central,
          benefits: 'Financial Assistance and Welfare Support',
          applicationProcess: 'Apply online through official portal',
          officialSourceUrl: 'https://www.india.gov.in',
          createdAt: now,
          updatedAt: now,
        );
      }

      if (!mounted) return;

      final appProvider = context.read<ApplicationProvider>();
      final userProfile = context.read<UserProfileProvider>();

      // Show quick loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.softSaffron),
        ),
      );

      await appProvider.startSession(
        scheme: scheme,
        userProfileAnswers: userProfile.answers,
        language: lang,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog

      final targetScheme = scheme;
      // Navigate to Smart Application Filler Preparation stage
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartFillerPreparationScreen(scheme: targetScheme),
        ),
      );
    } else if (action.action == 'open_document_vault') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
      );
    } else if (action.action == 'open_eligibility') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
      );
    } else if (action.action == 'open_schemes') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SchemesScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHi
              ? 'कार्रवाई उपलब्ध नहीं है: ${action.action}'
              : 'Action not available: ${action.action}'),
          backgroundColor: AppColors.deepNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();
    final lang = context.watch<LocaleProvider>().languageCode;
    final isHi = lang.startsWith('hi');

    // Auto scroll when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatbot.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.softSaffron,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.deepNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHi ? 'सहाय सहायक (SAHAY)' : 'SAHAY Assistance',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.selectedSchemeName != null
                        ? widget.selectedSchemeName!
                        : (isHi ? 'ऐप एवं योजना सहायक' : 'App & Scheme Guide'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.softSaffron,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: isHi ? 'चैट रीसेट करें' : 'Reset Chat',
            onPressed: () => chatbot.clearChat(language: lang),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Header Pill
          if (widget.selectedSchemeName != null || widget.currentScreen != 'home')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.softSaffron.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.deepNavy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isHi
                          ? 'सक्रिय संदर्भ: ${_getScreenLabel(widget.currentScreen, isHi)}${widget.selectedSchemeName != null ? ' • ${widget.selectedSchemeName}' : ''}'
                          : 'Active Context: ${_getScreenLabel(widget.currentScreen, isHi)}${widget.selectedSchemeName != null ? ' • ${widget.selectedSchemeName}' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatbot.messages.length + (chatbot.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatbot.messages.length) {
                  return _buildLoadingBubble();
                }
                final message = chatbot.messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // Suggested Questions Chips
          if (chatbot.suggestedQuestions.isNotEmpty && !chatbot.isLoading)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: chatbot.suggestedQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final q = chatbot.suggestedQuestions[index];
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.softSaffron, width: 1.2),
                    label: Text(
                      q,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _sendMessage(q),
                  );
                },
              ),
            ),

          // Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isHi
                            ? 'सहाय से कुछ भी पूछें...'
                            : 'Ask SAHAY about schemes, forms...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.indianTeal, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onSubmitted: (val) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.deepNavy,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
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

  Widget _buildMessageItem(ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    // Assistant Message
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.softSaffron,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.deepNavy, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(message.text),

                      // Navigation Action Button Chip
                      if (message.navigationAction != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleNavigationAction(message.navigationAction!),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.deepNavy),
                            label: Text(
                              message.navigationAction!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.softSaffron,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepNavy),
            ),
            SizedBox(width: 10),
            Text('Thinking...', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// Simple bold & markdown paragraph formatter
  Widget _buildFormattedText(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.deepNavy : const Color(0xFF334155),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  String _getScreenLabel(String screen, bool isHi) {
    switch (screen.toLowerCase()) {
      case 'home':
        return isHi ? 'होम स्क्रीन' : 'Home Screen';
      case 'scheme_detail':
        return isHi ? 'योजना विवरण' : 'Scheme Details';
      case 'how_to_apply':
        return isHi ? 'आवेदन कैसे करें' : 'How to Apply';
      case 'document_vault':
      case 'my_documents':
        return isHi ? 'दस्तावेज़ वॉल्ट' : 'Document Vault';
      case 'smart_filler_preparation':
      case 'smart_filler_portal':
        return isHi ? 'स्मार्ट फॉर्म फिलर' : 'Smart Application Filler';
      case 'questionnaire':
      case 'eligibility':
        return isHi ? 'पात्रता जांच' : 'Eligibility Assessment';
      default:
        return screen;
    }
  }
}

