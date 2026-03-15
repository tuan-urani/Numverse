import 'package:equatable/equatable.dart';

import 'package:test/src/locale/locale_key.dart';

class NumAiState extends Equatable {
  const NumAiState({
    required this.chatCost,
    required this.askTopics,
    required this.suggestedQuestions,
  });

  factory NumAiState.initial() {
    return const NumAiState(
      chatCost: 3,
      askTopics: <NumAiAskTopic>[
        NumAiAskTopic(
          iconSymbol: '✓',
          titleKey: LocaleKey.numaiAskTopicKnowledgeTitle,
          descriptionKey: LocaleKey.numaiAskTopicKnowledgeBody,
        ),
        NumAiAskTopic(
          iconSymbol: '★',
          titleKey: LocaleKey.numaiAskTopicPersonalTitle,
          descriptionKey: LocaleKey.numaiAskTopicPersonalBody,
        ),
        NumAiAskTopic(
          iconSymbol: '♥',
          titleKey: LocaleKey.numaiAskTopicCompatibilityTitle,
          descriptionKey: LocaleKey.numaiAskTopicCompatibilityBody,
        ),
      ],
      suggestedQuestions: <NumAiSuggestedQuestion>[
        NumAiSuggestedQuestion(
          textKey: LocaleKey.numaiQuestionUniverse,
          needsProfile: false,
        ),
        NumAiSuggestedQuestion(
          textKey: LocaleKey.numaiQuestionWhoAmI,
          needsProfile: true,
        ),
        NumAiSuggestedQuestion(
          textKey: LocaleKey.numaiQuestionNumberSeven,
          needsProfile: false,
        ),
      ],
    );
  }

  final int chatCost;
  final List<NumAiAskTopic> askTopics;
  final List<NumAiSuggestedQuestion> suggestedQuestions;

  @override
  List<Object?> get props => <Object?>[chatCost, askTopics, suggestedQuestions];
}

class NumAiAskTopic extends Equatable {
  const NumAiAskTopic({
    required this.iconSymbol,
    required this.titleKey,
    required this.descriptionKey,
  });

  final String iconSymbol;
  final String titleKey;
  final String descriptionKey;

  @override
  List<Object?> get props => <Object?>[iconSymbol, titleKey, descriptionKey];
}

class NumAiSuggestedQuestion extends Equatable {
  const NumAiSuggestedQuestion({
    required this.textKey,
    required this.needsProfile,
  });

  final String textKey;
  final bool needsProfile;

  @override
  List<Object?> get props => <Object?>[textKey, needsProfile];
}
