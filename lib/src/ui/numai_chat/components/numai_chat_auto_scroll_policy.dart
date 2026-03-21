import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

enum NumAiChatAutoScrollMode { none, jump, animate }

class NumAiChatAutoScrollSnapshot {
  const NumAiChatAutoScrollSnapshot({
    required this.messageCount,
    required this.isLoading,
    required this.lastMessageRole,
    required this.isNearBottom,
    required this.forceOnUserSend,
  });

  final int messageCount;
  final bool isLoading;
  final NumAiChatMessageRole? lastMessageRole;
  final bool isNearBottom;
  final bool forceOnUserSend;
}

NumAiChatAutoScrollSnapshot buildNumAiChatScrollSnapshot({
  required List<NumAiChatMessage> messages,
  required bool isLoading,
  required bool isNearBottom,
  required bool forceOnUserSend,
}) {
  return NumAiChatAutoScrollSnapshot(
    messageCount: messages.length,
    isLoading: isLoading,
    lastMessageRole: messages.isEmpty ? null : messages.last.role,
    isNearBottom: isNearBottom,
    forceOnUserSend: forceOnUserSend,
  );
}

NumAiChatAutoScrollMode decideNumAiChatAutoScroll({
  required NumAiChatAutoScrollSnapshot previous,
  required NumAiChatAutoScrollSnapshot current,
}) {
  final bool messageCountChanged =
      previous.messageCount != current.messageCount;
  final bool loadingChanged = previous.isLoading != current.isLoading;
  if (!messageCountChanged && !loadingChanged) {
    return NumAiChatAutoScrollMode.none;
  }

  if (previous.messageCount == 0 && current.messageCount > 0) {
    return NumAiChatAutoScrollMode.jump;
  }

  final int countDelta = current.messageCount - previous.messageCount;
  if (countDelta <= 0) {
    return loadingChanged && current.isNearBottom
        ? NumAiChatAutoScrollMode.jump
        : NumAiChatAutoScrollMode.none;
  }

  final bool isSingleAppend = countDelta == 1;
  final NumAiChatMessageRole? lastRole = current.lastMessageRole;
  if (lastRole == NumAiChatMessageRole.user) {
    final bool isComposerSendTransition =
        isSingleAppend && !previous.isLoading && current.isLoading;
    if (current.forceOnUserSend && isComposerSendTransition) {
      return NumAiChatAutoScrollMode.jump;
    }
    return current.isNearBottom
        ? NumAiChatAutoScrollMode.jump
        : NumAiChatAutoScrollMode.none;
  }

  if (lastRole == NumAiChatMessageRole.assistant) {
    return current.isNearBottom
        ? NumAiChatAutoScrollMode.animate
        : NumAiChatAutoScrollMode.none;
  }

  return current.isNearBottom
      ? NumAiChatAutoScrollMode.jump
      : NumAiChatAutoScrollMode.none;
}
