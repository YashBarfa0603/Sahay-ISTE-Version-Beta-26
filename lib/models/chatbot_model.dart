class NavigationActionModel {
  final String action;
  final String title;
  final String? schemeId;
  final String? schemeName;
  final String? route;
  final Map<String, dynamic>? parameters;

  const NavigationActionModel({
    required this.action,
    required this.title,
    this.schemeId,
    this.schemeName,
    this.route,
    this.parameters,
  });

  factory NavigationActionModel.fromMap(Map<String, dynamic> map) {
    return NavigationActionModel(
      action: map['action'] as String? ?? '',
      title: map['title'] as String? ?? 'Open',
      schemeId: map['scheme_id'] as String?,
      schemeName: map['scheme_name'] as String?,
      route: map['route'] as String?,
      parameters: map['parameters'] is Map ? Map<String, dynamic>.from(map['parameters'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'title': title,
      if (schemeId != null) 'scheme_id': schemeId,
      if (schemeName != null) 'scheme_name': schemeName,
      if (route != null) 'route': route,
      if (parameters != null) 'parameters': parameters,
    };
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestedQuestions;
  final NavigationActionModel? navigationAction;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestedQuestions = const [],
    this.navigationAction,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ContextPromptsModel {
  final String currentScreen;
  final List<String> suggestedQuestions;
  final String welcomeMessage;

  const ContextPromptsModel({
    required this.currentScreen,
    required this.suggestedQuestions,
    required this.welcomeMessage,
  });

  factory ContextPromptsModel.fromMap(Map<String, dynamic> map) {
    return ContextPromptsModel(
      currentScreen: map['current_screen'] as String? ?? 'home',
      suggestedQuestions: (map['suggested_questions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      welcomeMessage: map['welcome_message'] as String? ??
          'Namaste! Welcome to SAHAY Assistance.',
    );
  }
}

