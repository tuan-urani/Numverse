import 'dart:async';

import 'package:equatable/equatable.dart';

typedef DeductSoulPoints = Future<bool> Function(int amount);

sealed class NumAiChatEvent extends Equatable {
  const NumAiChatEvent();
}

final class NumAiChatMessageSent extends NumAiChatEvent {
  const NumAiChatMessageSent({
    required this.rawMessage,
    required this.hasProfile,
    required this.deductSoulPoints,
    required this.completer,
  });

  final String rawMessage;
  final bool hasProfile;
  final DeductSoulPoints deductSoulPoints;
  final Completer<bool> completer;

  @override
  List<Object?> get props => <Object?>[
    rawMessage,
    hasProfile,
    deductSoulPoints,
  ];
}

final class NumAiChatInsufficientWarningCleared extends NumAiChatEvent {
  const NumAiChatInsufficientWarningCleared();

  @override
  List<Object?> get props => <Object?>[];
}

final class NumAiChatQuickSuggestionApplied extends NumAiChatEvent {
  const NumAiChatQuickSuggestionApplied(this.suggestion);

  final String suggestion;

  @override
  List<Object?> get props => <Object?>[suggestion];
}

final class NumAiChatPendingProfileQuestionCleared extends NumAiChatEvent {
  const NumAiChatPendingProfileQuestionCleared();

  @override
  List<Object?> get props => <Object?>[];
}

final class NumAiChatPendingQuestionAnswerAppended extends NumAiChatEvent {
  const NumAiChatPendingQuestionAnswerAppended();

  @override
  List<Object?> get props => <Object?>[];
}

final class NumAiChatConversationReset extends NumAiChatEvent {
  const NumAiChatConversationReset();

  @override
  List<Object?> get props => <Object?>[];
}
