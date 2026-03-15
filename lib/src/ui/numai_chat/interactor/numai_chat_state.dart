import 'package:equatable/equatable.dart';

class NumAiChatState extends Equatable {
  const NumAiChatState({
    required this.messages,
    required this.isLoading,
    required this.pendingProfileQuestion,
    required this.showInsufficientPointsWarning,
  });

  factory NumAiChatState.initial() {
    return const NumAiChatState(
      messages: <NumAiChatMessage>[],
      isLoading: false,
      pendingProfileQuestion: null,
      showInsufficientPointsWarning: false,
    );
  }

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final String? pendingProfileQuestion;
  final bool showInsufficientPointsWarning;

  bool get isEmpty => messages.isEmpty;

  NumAiChatState copyWith({
    List<NumAiChatMessage>? messages,
    bool? isLoading,
    String? pendingProfileQuestion,
    bool clearPendingProfileQuestion = false,
    bool? showInsufficientPointsWarning,
  }) {
    return NumAiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      pendingProfileQuestion: clearPendingProfileQuestion
          ? null
          : pendingProfileQuestion ?? this.pendingProfileQuestion,
      showInsufficientPointsWarning:
          showInsufficientPointsWarning ?? this.showInsufficientPointsWarning,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messages,
    isLoading,
    pendingProfileQuestion,
    showInsufficientPointsWarning,
  ];
}

class NumAiChatMessage extends Equatable {
  const NumAiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.hasActionButton = false,
  });

  final String id;
  final NumAiChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool hasActionButton;

  @override
  List<Object?> get props => <Object?>[
    id,
    role,
    content,
    timestamp,
    hasActionButton,
  ];
}

enum NumAiChatMessageRole { user, assistant }
