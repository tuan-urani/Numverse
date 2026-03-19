import 'package:equatable/equatable.dart';

class NumAiChatState extends Equatable {
  const NumAiChatState({
    required this.messages,
    required this.isLoading,
    required this.pendingProfileQuestion,
    required this.showInsufficientPointsWarning,
    required this.threadId,
    required this.activeProfileId,
    required this.typingMessageId,
  });

  factory NumAiChatState.initial() {
    return const NumAiChatState(
      messages: <NumAiChatMessage>[],
      isLoading: false,
      pendingProfileQuestion: null,
      showInsufficientPointsWarning: false,
      threadId: null,
      activeProfileId: null,
      typingMessageId: null,
    );
  }

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final String? pendingProfileQuestion;
  final bool showInsufficientPointsWarning;
  final String? threadId;
  final String? activeProfileId;
  final String? typingMessageId;

  bool get isEmpty => messages.isEmpty;

  NumAiChatState copyWith({
    List<NumAiChatMessage>? messages,
    bool? isLoading,
    String? pendingProfileQuestion,
    bool clearPendingProfileQuestion = false,
    bool? showInsufficientPointsWarning,
    String? threadId,
    bool clearThreadId = false,
    String? activeProfileId,
    bool clearActiveProfileId = false,
    String? typingMessageId,
    bool clearTypingMessageId = false,
  }) {
    return NumAiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      pendingProfileQuestion: clearPendingProfileQuestion
          ? null
          : pendingProfileQuestion ?? this.pendingProfileQuestion,
      showInsufficientPointsWarning:
          showInsufficientPointsWarning ?? this.showInsufficientPointsWarning,
      threadId: clearThreadId ? null : threadId ?? this.threadId,
      activeProfileId: clearActiveProfileId
          ? null
          : activeProfileId ?? this.activeProfileId,
      typingMessageId: clearTypingMessageId
          ? null
          : typingMessageId ?? this.typingMessageId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messages,
    isLoading,
    pendingProfileQuestion,
    showInsufficientPointsWarning,
    threadId,
    activeProfileId,
    typingMessageId,
  ];
}

class NumAiChatMessage extends Equatable {
  const NumAiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.hasActionButton = false,
    this.followUpSuggestions = const <String>[],
    this.fallbackReason,
  });

  final String id;
  final NumAiChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool hasActionButton;
  final List<String> followUpSuggestions;
  final String? fallbackReason;

  @override
  List<Object?> get props => <Object?>[
    id,
    role,
    content,
    timestamp,
    hasActionButton,
    followUpSuggestions,
    fallbackReason,
  ];
}

enum NumAiChatMessageRole { user, assistant }
