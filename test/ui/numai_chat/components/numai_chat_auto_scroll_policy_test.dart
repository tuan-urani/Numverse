import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/ui/numai_chat/components/numai_chat_auto_scroll_policy.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

NumAiChatMessage _message({
  required String id,
  required NumAiChatMessageRole role,
}) {
  return NumAiChatMessage(
    id: id,
    role: role,
    content: id,
    timestamp: DateTime(2026, 1, 1, 9, 0, id.hashCode % 59),
  );
}

NumAiChatAutoScrollSnapshot _snapshot({
  required List<NumAiChatMessage> messages,
  required bool isLoading,
  required bool isNearBottom,
}) {
  return buildNumAiChatScrollSnapshot(
    messages: messages,
    isLoading: isLoading,
    isNearBottom: isNearBottom,
    forceOnUserSend: true,
  );
}

void main() {
  group('decideNumAiChatAutoScroll', () {
    final NumAiChatMessage firstAssistant = _message(
      id: 'assistant-1',
      role: NumAiChatMessageRole.assistant,
    );

    test('returns none when loading changes and user is not near bottom', () {
      final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
        previous: _snapshot(
          messages: <NumAiChatMessage>[firstAssistant],
          isLoading: false,
          isNearBottom: false,
        ),
        current: _snapshot(
          messages: <NumAiChatMessage>[firstAssistant],
          isLoading: true,
          isNearBottom: false,
        ),
      );

      expect(mode, NumAiChatAutoScrollMode.none);
    });

    test('returns jump when loading changes and user is near bottom', () {
      final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
        previous: _snapshot(
          messages: <NumAiChatMessage>[firstAssistant],
          isLoading: false,
          isNearBottom: true,
        ),
        current: _snapshot(
          messages: <NumAiChatMessage>[firstAssistant],
          isLoading: true,
          isNearBottom: true,
        ),
      );

      expect(mode, NumAiChatAutoScrollMode.jump);
    });

    test('returns jump when user message is appended from composer send', () {
      final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
        previous: _snapshot(
          messages: <NumAiChatMessage>[firstAssistant],
          isLoading: false,
          isNearBottom: false,
        ),
        current: _snapshot(
          messages: <NumAiChatMessage>[
            firstAssistant,
            _message(id: 'user-2', role: NumAiChatMessageRole.user),
          ],
          isLoading: true,
          isNearBottom: false,
        ),
      );

      expect(mode, NumAiChatAutoScrollMode.jump);
    });

    test('returns animate when assistant message is appended near bottom', () {
      final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
        previous: _snapshot(
          messages: <NumAiChatMessage>[
            _message(id: 'user-1', role: NumAiChatMessageRole.user),
          ],
          isLoading: true,
          isNearBottom: true,
        ),
        current: _snapshot(
          messages: <NumAiChatMessage>[
            _message(id: 'user-1', role: NumAiChatMessageRole.user),
            _message(id: 'assistant-2', role: NumAiChatMessageRole.assistant),
          ],
          isLoading: false,
          isNearBottom: true,
        ),
      );

      expect(mode, NumAiChatAutoScrollMode.animate);
    });

    test(
      'returns none when assistant message is appended away from bottom',
      () {
        final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
          previous: _snapshot(
            messages: <NumAiChatMessage>[
              _message(id: 'user-1', role: NumAiChatMessageRole.user),
            ],
            isLoading: true,
            isNearBottom: false,
          ),
          current: _snapshot(
            messages: <NumAiChatMessage>[
              _message(id: 'user-1', role: NumAiChatMessageRole.user),
              _message(id: 'assistant-2', role: NumAiChatMessageRole.assistant),
            ],
            isLoading: false,
            isNearBottom: false,
          ),
        );

        expect(mode, NumAiChatAutoScrollMode.none);
      },
    );
  });
}
