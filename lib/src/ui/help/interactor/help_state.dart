import 'package:equatable/equatable.dart';

import 'package:test/src/locale/locale_key.dart';

class HelpState extends Equatable {
  const HelpState({required this.faqs, required this.expandedFaqId});

  factory HelpState.initial() {
    return const HelpState(
      expandedFaqId: null,
      faqs: <HelpFaqItem>[
        HelpFaqItem(
          id: 1,
          questionKey: LocaleKey.helpFaqQuestionOne,
          answerKey: LocaleKey.helpFaqAnswerOne,
        ),
        HelpFaqItem(
          id: 2,
          questionKey: LocaleKey.helpFaqQuestionTwo,
          answerKey: LocaleKey.helpFaqAnswerTwo,
        ),
        HelpFaqItem(
          id: 3,
          questionKey: LocaleKey.helpFaqQuestionThree,
          answerKey: LocaleKey.helpFaqAnswerThree,
        ),
        HelpFaqItem(
          id: 4,
          questionKey: LocaleKey.helpFaqQuestionFour,
          answerKey: LocaleKey.helpFaqAnswerFour,
        ),
        HelpFaqItem(
          id: 5,
          questionKey: LocaleKey.helpFaqQuestionFive,
          answerKey: LocaleKey.helpFaqAnswerFive,
        ),
        HelpFaqItem(
          id: 6,
          questionKey: LocaleKey.helpFaqQuestionSix,
          answerKey: LocaleKey.helpFaqAnswerSix,
        ),
        HelpFaqItem(
          id: 7,
          questionKey: LocaleKey.helpFaqQuestionSeven,
          answerKey: LocaleKey.helpFaqAnswerSeven,
        ),
        HelpFaqItem(
          id: 8,
          questionKey: LocaleKey.helpFaqQuestionEight,
          answerKey: LocaleKey.helpFaqAnswerEight,
        ),
      ],
    );
  }

  final List<HelpFaqItem> faqs;
  final int? expandedFaqId;

  HelpState copyWith({
    List<HelpFaqItem>? faqs,
    int? expandedFaqId,
    bool clearExpandedFaqId = false,
  }) {
    return HelpState(
      faqs: faqs ?? this.faqs,
      expandedFaqId: clearExpandedFaqId
          ? null
          : expandedFaqId ?? this.expandedFaqId,
    );
  }

  @override
  List<Object?> get props => <Object?>[faqs, expandedFaqId];
}

class HelpFaqItem extends Equatable {
  const HelpFaqItem({
    required this.id,
    required this.questionKey,
    required this.answerKey,
  });

  final int id;
  final String questionKey;
  final String answerKey;

  @override
  List<Object?> get props => <Object?>[id, questionKey, answerKey];
}
