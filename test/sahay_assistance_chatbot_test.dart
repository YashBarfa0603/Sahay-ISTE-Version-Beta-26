import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahay/models/chatbot_model.dart';
import 'package:sahay/providers/chatbot_provider.dart';
import 'package:sahay/providers/locale_provider.dart';
import 'package:sahay/providers/application_provider.dart';
import 'package:sahay/providers/user_profile_provider.dart';
import 'package:sahay/screens/sahay_assistance_screen.dart';
import 'package:sahay/widgets/sahay_assistance_fab.dart';

void main() {
  group('Chatbot Model Tests', () {
    test('NavigationActionModel serialization and deserialization', () {
      final map = {
        'action': 'start_fill_with_sahay',
        'title': 'Start Fill with SAHAY',
        'scheme_id': 'PM_KISAN_001',
        'scheme_name': 'PM-KISAN',
      };

      final model = NavigationActionModel.fromMap(map);
      expect(model.action, 'start_fill_with_sahay');
      expect(model.title, 'Start Fill with SAHAY');
      expect(model.schemeId, 'PM_KISAN_001');
      expect(model.schemeName, 'PM-KISAN');

      final serialized = model.toMap();
      expect(serialized['action'], 'start_fill_with_sahay');
      expect(serialized['scheme_id'], 'PM_KISAN_001');
    });

    test('ChatMessage default values and properties', () {
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Hello SAHAY',
        isUser: true,
      );

      expect(msg.id, 'msg_1');
      expect(msg.text, 'Hello SAHAY');
      expect(msg.isUser, true);
      expect(msg.isError, false);
      expect(msg.suggestedQuestions, isEmpty);
      expect(msg.navigationAction, isNull);
    });

    test('ContextPromptsModel parsing', () {
      final map = {
        'current_screen': 'scheme_detail',
        'suggested_questions': ['How to apply?', 'What documents needed?'],
        'welcome_message': 'Welcome to Scheme Details',
      };

      final model = ContextPromptsModel.fromMap(map);
      expect(model.currentScreen, 'scheme_detail');
      expect(model.suggestedQuestions.length, 2);
      expect(model.welcomeMessage, 'Welcome to Scheme Details');
    });
  });

  group('ChatbotProvider Tests', () {
    test('Initial state and clearChat', () async {
      final provider = ChatbotProvider();
      expect(provider.messages, isEmpty);
      expect(provider.isLoading, false);

      await provider.setContext(
        screen: 'home',
        language: 'en',
      );

      expect(provider.messages.isNotEmpty, true);
      expect(provider.messages.first.isUser, false);

      await provider.clearChat(language: 'en');
      // After clearChat and reset, messages list should contain welcome prompt
      expect(provider.messages.length, 1);
    });

    test('sendUserMessage adds user message and returns fallback or assistant message', () async {
      final provider = ChatbotProvider();
      await provider.setContext(screen: 'home', language: 'en');

      final initialCount = provider.messages.length;
      await provider.sendUserMessage('How do I apply for PM Kisan?', language: 'en');

      // Should add 1 user message + 1 assistant message
      expect(provider.messages.length, initialCount + 2);
      expect(provider.messages[initialCount].isUser, true);
      expect(provider.messages[initialCount].text, 'How do I apply for PM Kisan?');
      expect(provider.messages[initialCount + 1].isUser, false);
      expect(provider.isLoading, false);
    });
  });

  group('SahayAssistanceScreen Widget Tests', () {
    testWidgets('Renders AppBar, context header, and input field', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => ChatbotProvider()),
            ChangeNotifierProvider(create: (_) => ApplicationProvider()),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ],
          child: const MaterialApp(
            home: SahayAssistanceScreen(
              currentScreen: 'scheme_detail',
              selectedSchemeId: 'PM_KISAN_001',
              selectedSchemeName: 'PM-KISAN Samman Nidhi',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check AppBar branding
      expect(find.text('SAHAY Assistance'), findsOneWidget);
      expect(find.text('PM-KISAN Samman Nidhi'), findsOneWidget);

      // Check TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('SahayAssistanceFAB renders and has correct label', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              floatingActionButton: SahayAssistanceFAB(
                currentScreen: 'home',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ask SAHAY'), findsOneWidget);
      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    });
  });
}

