import 'package:flutter/foundation.dart';
import 'package:sahay/models/chatbot_model.dart';
import 'package:sahay/services/api_client.dart';

class ChatbotApiService {
  final ApiClient _apiClient;

  ChatbotApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Sends user message to backend assistance chatbot.
  Future<ChatMessage> sendMessage({
    required String message,
    String? conversationId,
    String? currentScreen,
    String? currentModule,
    String? currentWorkflowStage,
    String? selectedSchemeId,
    String? selectedSchemeName,
    String language = 'en',
  }) async {
    final payload = {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
      if (currentScreen != null) 'current_screen': currentScreen,
      if (currentModule != null) 'current_module': currentModule,
      if (currentWorkflowStage != null) 'current_workflow_stage': currentWorkflowStage,
      if (selectedSchemeId != null) 'selected_scheme_id': selectedSchemeId,
      if (selectedSchemeName != null) 'selected_scheme_name': selectedSchemeName,
      'app_language': language,
    };

    try {
      final response = await _apiClient.post(
        '/api/assistance/chat',
        data: payload,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final text = data['assistant_message'] as String? ?? '';
        final suggestions = (data['suggested_questions'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        NavigationActionModel? nav;
        if (data['navigation_action'] is Map) {
          nav = NavigationActionModel.fromMap(
              Map<String, dynamic>.from(data['navigation_action'] as Map));
        }

        return ChatMessage(
          id: data['conversation_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isUser: false,
          suggestedQuestions: suggestions,
          navigationAction: nav,
        );
      }
    } catch (e) {
      debugPrint('ChatbotApiService: sendMessage error: $e');
    }

    // Client-side offline fallback
    final isHi = language.startsWith('hi');
    return ChatMessage(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      text: isHi
          ? 'नमस्ते! मैं सहाय सहायक हूँ। आप मुझसे सरकारी योजनाओं, पात्रता और "Fill with SAHAY" के बारे में पूछ सकते हैं।'
          : 'Namaste! I am SAHAY Assistance. I can help you understand schemes, check eligibility, and prepare applications with Fill with SAHAY.',
      isUser: false,
      suggestedQuestions: isHi
          ? ['"Fill with SAHAY" क्या है?', 'मेरी पात्रता कैसे जांचें?', 'दस्तावेज़ वॉल्ट क्या है?']
          : ['What is Fill with SAHAY?', 'How do I check eligibility?', 'What is Document Vault?'],
      navigationAction: const NavigationActionModel(
        action: 'open_schemes',
        title: 'Browse Schemes',
      ),
    );
  }

  /// Fetches screen-context suggested prompts from backend.
  Future<ContextPromptsModel> getContextPrompts({
    String? currentScreen,
    String? selectedSchemeId,
    String language = 'en',
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/assistance/context-prompts',
        queryParameters: {
          if (currentScreen != null) 'current_screen': currentScreen,
          if (selectedSchemeId != null) 'selected_scheme_id': selectedSchemeId,
          'language': language,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return ContextPromptsModel.fromMap(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('ChatbotApiService: getContextPrompts error: $e');
    }

    final isHi = language.startsWith('hi');
    return ContextPromptsModel(
      currentScreen: currentScreen ?? 'home',
      suggestedQuestions: isHi
          ? ['सहाय ऐप कैसे काम करता है?', 'योजनाएं कैसे खोजें?', 'दस्तावेज़ कैसे अपलोड करें?']
          : ['How does SAHAY work?', 'How to find schemes?', 'How to upload documents?'],
      welcomeMessage: isHi
          ? 'नमस्ते! मैं सहाय सहायक (SAHAY Assistance) हूँ। मैं आपकी क्या मदद कर सकता हूँ?'
          : 'Namaste! Welcome to SAHAY Assistance. How can I help you today?',
    );
  }
}

