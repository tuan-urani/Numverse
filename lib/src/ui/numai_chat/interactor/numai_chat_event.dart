import 'dart:async';

import 'package:equatable/equatable.dart';

typedef DeductSoulPoints = Future<bool> Function(int amount);
typedef SyncSoulPoints = Future<void> Function(int soulPoints);

sealed class NumAiChatEvent extends Equatable {
  const NumAiChatEvent();
}

final class NumAiChatHistoryRequested extends NumAiChatEvent {
  const NumAiChatHistoryRequested({
    required this.hasCloudSession,
    required this.profileId,
    required this.cloudUserId,
    required this.forceRefresh,
  });

  final bool hasCloudSession;
  final String? profileId;
  final String? cloudUserId;
  final bool forceRefresh;

  @override
  List<Object?> get props => <Object?>[
    hasCloudSession,
    profileId,
    cloudUserId,
    forceRefresh,
  ];
}

final class NumAiChatMessageSent extends NumAiChatEvent {
  const NumAiChatMessageSent({
    required this.rawMessage,
    required this.hasProfile,
    required this.hasCloudSession,
    required this.profileId,
    required this.cloudUserId,
    required this.locale,
    required this.deductSoulPoints,
    required this.syncSoulPoints,
    required this.completer,
  });

  final String rawMessage;
  final bool hasProfile;
  final bool hasCloudSession;
  final String? profileId;
  final String? cloudUserId;
  final String? locale;
  final DeductSoulPoints deductSoulPoints;
  final SyncSoulPoints syncSoulPoints;
  final Completer<bool> completer;

  @override
  List<Object?> get props => <Object?>[
    rawMessage,
    hasProfile,
    hasCloudSession,
    profileId,
    cloudUserId,
    locale,
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
  const NumAiChatConversationReset({required this.cloudUserId});

  final String? cloudUserId;

  @override
  List<Object?> get props => <Object?>[cloudUserId];
}
