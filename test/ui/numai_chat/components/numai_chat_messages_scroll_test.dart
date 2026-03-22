import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/numai_chat/components/numai_chat_messages.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

List<NumAiChatMessage> _buildMessages(int count) {
  final List<NumAiChatMessage> messages = <NumAiChatMessage>[];
  for (int index = 0; index < count; index += 1) {
    final bool isUser = index.isEven;
    messages.add(
      NumAiChatMessage(
        id: 'message-$index',
        role: isUser
            ? NumAiChatMessageRole.user
            : NumAiChatMessageRole.assistant,
        content: 'message $index content repeated repeated repeated',
        timestamp: DateTime(2026, 1, 1, 8, 0, index % 59),
      ),
    );
  }
  return messages;
}

ScrollableState _scrollableState(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable).first);
}

double _pixels(WidgetTester tester) => _scrollableState(tester).position.pixels;

double _max(WidgetTester tester) =>
    _scrollableState(tester).position.maxScrollExtent;

Future<void> _pumpChat(
  WidgetTester tester, {
  required List<NumAiChatMessage> messages,
  required bool isLoading,
  bool isHistoryLoading = false,
  String? typingMessageId,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 520,
          child: NumAiChatMessages(
            key: const ValueKey<String>('chat-messages'),
            messages: messages,
            isLoading: isLoading,
            isHistoryLoading: isHistoryLoading,
            typingMessageId: typingMessageId,
            onAssistantTypingCompleted: (_) {},
            onActionTap: () {},
            onQuickSuggestionTap: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows blocking loader and hides message list while history is loading',
    (WidgetTester tester) async {
      final List<NumAiChatMessage> baseMessages = _buildMessages(6);
      await _pumpChat(
        tester,
        messages: baseMessages,
        isLoading: true,
        isHistoryLoading: true,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('message 0 content'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'keeps position on loading-only, jumps on user send, animates on assistant append',
    (WidgetTester tester) async {
      final List<NumAiChatMessage> baseMessages = _buildMessages(24);
      await _pumpChat(tester, messages: baseMessages, isLoading: false);
      await tester.pumpAndSettle();

      _scrollableState(tester).position.jumpTo(_max(tester));
      await tester.pump();
      _scrollableState(
        tester,
      ).position.jumpTo((_max(tester) - 280).clamp(0, _max(tester)));
      await tester.pump();
      final double beforeLoadingToggle = _pixels(tester);

      await _pumpChat(tester, messages: baseMessages, isLoading: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pixels(tester), closeTo(beforeLoadingToggle, 0.5));

      await _pumpChat(tester, messages: baseMessages, isLoading: false);
      await tester.pump();

      final List<NumAiChatMessage> withUserMessage = <NumAiChatMessage>[
        ...baseMessages,
        NumAiChatMessage(
          id: 'message-user-send',
          role: NumAiChatMessageRole.user,
          content: 'new user message',
          timestamp: DateTime(2026, 1, 1, 10, 0, 0),
        ),
      ];
      await _pumpChat(tester, messages: withUserMessage, isLoading: true);
      await tester.pump();
      await tester.pump();
      expect(_pixels(tester), greaterThanOrEqualTo(_max(tester) - 2));
      _scrollableState(tester).position.jumpTo(_max(tester));
      await tester.pump();

      final List<NumAiChatMessage> withAssistantMessage = <NumAiChatMessage>[
        ...withUserMessage,
        NumAiChatMessage(
          id: 'message-assistant-reply',
          role: NumAiChatMessageRole.assistant,
          content: 'assistant response with enough content to increase height',
          timestamp: DateTime(2026, 1, 1, 10, 0, 1),
        ),
      ];
      final double beforeAssistantAppend = _pixels(tester);
      await _pumpChat(
        tester,
        messages: withAssistantMessage,
        isLoading: false,
        typingMessageId: 'message-assistant-reply',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      final double afterAssistantAnimation = _pixels(tester);

      expect(afterAssistantAnimation, greaterThan(beforeAssistantAppend));
      expect(afterAssistantAnimation, greaterThanOrEqualTo(_max(tester) - 2));
    },
  );
}
