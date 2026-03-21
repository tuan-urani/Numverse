import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/numai_chat/components/numai_chat_messages.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

List<NumAiChatMessage> _buildMessages({
  required int count,
  required String typingMessageId,
}) {
  final List<NumAiChatMessage> messages = <NumAiChatMessage>[];
  for (int index = 0; index < count; index += 1) {
    final bool isLast = index == count - 1;
    final bool isUser = !isLast && index.isEven;
    final String id = isLast ? typingMessageId : 'message-$index';
    messages.add(
      NumAiChatMessage(
        id: id,
        role: isUser
            ? NumAiChatMessageRole.user
            : NumAiChatMessageRole.assistant,
        content: isLast
            ? 'final assistant response with typing animation'
            : 'message $index content repeated repeated repeated',
        timestamp: DateTime(2026, 1, 1, 8, 0, index % 59),
      ),
    );
  }
  return messages;
}

ScrollableState _scrollableState(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable).first);
}

double _maxScrollExtent(WidgetTester tester) {
  return _scrollableState(tester).position.maxScrollExtent;
}

void main() {
  testWidgets(
    'assistant message typewriter completes once and does not replay after scrolling away and back',
    (WidgetTester tester) async {
      const String typingMessageId = 'assistant-final';
      final List<NumAiChatMessage> messages = _buildMessages(
        count: 22,
        typingMessageId: typingMessageId,
      );
      String? currentTypingMessageId = typingMessageId;
      int onCompletedCount = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SizedBox(
                  height: 520,
                  child: NumAiChatMessages(
                    messages: messages,
                    isLoading: false,
                    typingMessageId: currentTypingMessageId,
                    onAssistantTypingCompleted: (String messageId) {
                      onCompletedCount += 1;
                      setState(() {
                        if (currentTypingMessageId == messageId) {
                          currentTypingMessageId = null;
                        }
                      });
                    },
                    onActionTap: () {},
                    onQuickSuggestionTap: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      _scrollableState(tester).position.jumpTo(_maxScrollExtent(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2600));

      expect(currentTypingMessageId, isNull);
      expect(onCompletedCount, 1);

      _scrollableState(tester).position.jumpTo(0);
      await tester.pump();
      _scrollableState(tester).position.jumpTo(_maxScrollExtent(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(currentTypingMessageId, isNull);
      expect(onCompletedCount, 1);
    },
  );
}
