import 'package:flutter/foundation.dart';
import 'package:sahay/models/chatbot_model.dart';
import 'package:sahay/services/chatbot_api_service.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotApiService _apiService;

  final List<ChatMessage> _messages = [];
  List<String> _suggestedQuestions = [];
  String? _conversationId;
  bool _isLoading = false;
  String _currentScreen = 'home';
  String? _selectedSchemeId;
  String? _selectedSchemeName;
  bool _initialized = false;

  ChatbotProvider({ChatbotApiService? apiService})
      : _apiService = apiService ?? ChatbotApiService();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<String> get suggestedQuestions => List.unmodifiable(_suggestedQuestions);
  bool get isLoading => _isLoading;
  String get currentScreen => _currentScreen;
  String? get selectedSchemeId => _selectedSchemeId;
  String? get selectedSchemeName => _selectedSchemeName;

  /// Initializes chatbot context based on the user's active screen.
  Future<void> setContext({
    required String screen,
    String? schemeId,
    String? schemeName,
    String language = 'en',
  }) async {
    _currentScreen = screen;
    _selectedSchemeId = schemeId;
    _selectedSchemeName = schemeName;

    if (!_initialized || _messages.isEmpty) {
      _isLoading = true;
      notifyListeners();

      final prompts = await _apiService.getContextPrompts(
        currentScreen: screen,
        selectedSchemeId: schemeId,
        language: language,
      );

      _suggestedQuestions = prompts.suggestedQuestions;

      // Add initial greeting if chat is empty
      if (_messages.isEmpty) {
        _messages.add(
          ChatMessage(
            id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            text: prompts.welcomeMessage,
            isUser: false,
            suggestedQuestions: prompts.suggestedQuestions,
          ),
        );
      }

      _initialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a user question to the chatbot.
  Future<void> sendUserMessage(String text, {String language = 'en'}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: cleanText,
      isUser: true,
    );

    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final assistantMsg = await _apiService.sendMessage(
        message: cleanText,
        conversationId: _conversationId,
        currentScreen: _currentScreen,
        selectedSchemeId: _selectedSchemeId,
        selectedSchemeName: _selectedSchemeName,
        language: language,
      );

      _conversationId = assistantMsg.id;
      _messages.add(assistantMsg);
      if (assistantMsg.suggestedQuestions.isNotEmpty) {
        _suggestedQuestions = assistantMsg.suggestedQuestions;
      }
    } catch (e) {
      debugPrint('ChatbotProvider: error sending message: $e');
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          text: language.startsWith('hi')
              ? 'क्षमा करें, संदेश भेजने में समस्या हुई। कृपया पुनः प्रयास करें।'
              : 'Sorry, I encountered an issue connecting to the assistant. Please try again.',
          isUser: false,
          isError: true,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the chat conversation history.
  Future<void> clearChat({String language = 'en'}) async {
    _messages.clear();
    _suggestedQuestions.clear();
    _conversationId = null;
    _initialized = false;
    notifyListeners();
    await setContext(
      screen: _currentScreen,
      schemeId: _selectedSchemeId,
      schemeName: _selectedSchemeName,
      language: language,
    );
  }
}

