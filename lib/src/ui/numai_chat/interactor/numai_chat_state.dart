import 'package:equatable/equatable.dart';

class NumAiChatState extends Equatable {
  const NumAiChatState({
    required this.messages,
    required this.isLoading,
    required this.pendingProfileQuestion,
    required this.showInsufficientPointsWarning,
    required this.threadId,
    required this.activeProfileId,
  });

  factory NumAiChatState.initial() {
    return const NumAiChatState(
      messages: <NumAiChatMessage>[],
      isLoading: false,
      pendingProfileQuestion: null,
      showInsufficientPointsWarning: false,
      threadId: null,
      activeProfileId: null,
    );
  }

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final String? pendingProfileQuestion;
  final bool showInsufficientPointsWarning;
  final String? threadId;
  final String? activeProfileId;

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
  });

  final String id;
  final NumAiChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool hasActionButton;
  final List<String> followUpSuggestions;

  @override
  List<Object?> get props => <Object?>[
    id,
    role,
    content,
    timestamp,
    hasActionButton,
    followUpSuggestions,
  ];
}

enum NumAiChatMessageRole { user, assistant }
