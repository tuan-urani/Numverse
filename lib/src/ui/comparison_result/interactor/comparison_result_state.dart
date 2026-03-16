import 'package:equatable/equatable.dart';

class ComparisonResultState extends Equatable {
  const ComparisonResultState({
    required this.languageCode,
    required this.selfProfileId,
    required this.targetProfileId,
    required this.selfName,
    required this.selfDate,
    required this.selfLifePath,
    required this.selfSoul,
    required this.selfPersonality,
    required this.selfExpression,
    required this.targetName,
    required this.targetRelation,
    required this.targetDate,
    required this.targetLifePath,
    required this.targetSoul,
    required this.targetPersonality,
    required this.targetExpression,
    required this.overallScore,
    required this.coreScore,
    required this.communicationScore,
    required this.soulScore,
    required this.personalityScore,
    required this.strengths,
    required this.challenges,
    required this.advice,
    required this.quote,
  });

  factory ComparisonResultState.initial() {
    return const ComparisonResultState(
      languageCode: 'vi',
      selfProfileId: '',
      targetProfileId: '',
      selfName: '',
      selfDate: '',
      selfLifePath: 0,
      selfSoul: 0,
      selfPersonality: 0,
      selfExpression: 0,
      targetName: '',
      targetRelation: '',
      targetDate: '',
      targetLifePath: 0,
      targetSoul: 0,
      targetPersonality: 0,
      targetExpression: 0,
      overallScore: 0,
      coreScore: 0,
      communicationScore: 0,
      soulScore: 0,
      personalityScore: 0,
      strengths: <String>[],
      challenges: <String>[],
      advice: <String>[],
      quote: '',
    );
  }

  final String languageCode;
  final String selfProfileId;
  final String targetProfileId;

  final String selfName;
  final String selfDate;
  final int selfLifePath;
  final int selfSoul;
  final int selfPersonality;
  final int selfExpression;

  final String targetName;
  final String targetRelation;
  final String targetDate;
  final int targetLifePath;
  final int targetSoul;
  final int targetPersonality;
  final int targetExpression;

  final int overallScore;
  final int coreScore;
  final int communicationScore;
  final int soulScore;
  final int personalityScore;
  final List<String> strengths;
  final List<String> challenges;
  final List<String> advice;
  final String quote;

  ComparisonResultState copyWith({
    String? languageCode,
    String? selfProfileId,
    String? targetProfileId,
    String? selfName,
    String? selfDate,
    int? selfLifePath,
    int? selfSoul,
    int? selfPersonality,
    int? selfExpression,
    String? targetName,
    String? targetRelation,
    String? targetDate,
    int? targetLifePath,
    int? targetSoul,
    int? targetPersonality,
    int? targetExpression,
    int? overallScore,
    int? coreScore,
    int? communicationScore,
    int? soulScore,
    int? personalityScore,
    List<String>? strengths,
    List<String>? challenges,
    List<String>? advice,
    String? quote,
  }) {
    return ComparisonResultState(
      languageCode: languageCode ?? this.languageCode,
      selfProfileId: selfProfileId ?? this.selfProfileId,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      selfName: selfName ?? this.selfName,
      selfDate: selfDate ?? this.selfDate,
      selfLifePath: selfLifePath ?? this.selfLifePath,
      selfSoul: selfSoul ?? this.selfSoul,
      selfPersonality: selfPersonality ?? this.selfPersonality,
      selfExpression: selfExpression ?? this.selfExpression,
      targetName: targetName ?? this.targetName,
      targetRelation: targetRelation ?? this.targetRelation,
      targetDate: targetDate ?? this.targetDate,
      targetLifePath: targetLifePath ?? this.targetLifePath,
      targetSoul: targetSoul ?? this.targetSoul,
      targetPersonality: targetPersonality ?? this.targetPersonality,
      targetExpression: targetExpression ?? this.targetExpression,
      overallScore: overallScore ?? this.overallScore,
      coreScore: coreScore ?? this.coreScore,
      communicationScore: communicationScore ?? this.communicationScore,
      soulScore: soulScore ?? this.soulScore,
      personalityScore: personalityScore ?? this.personalityScore,
      strengths: strengths ?? this.strengths,
      challenges: challenges ?? this.challenges,
      advice: advice ?? this.advice,
      quote: quote ?? this.quote,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    languageCode,
    selfProfileId,
    targetProfileId,
    selfName,
    selfDate,
    selfLifePath,
    selfSoul,
    selfPersonality,
    selfExpression,
    targetName,
    targetRelation,
    targetDate,
    targetLifePath,
    targetSoul,
    targetPersonality,
    targetExpression,
    overallScore,
    coreScore,
    communicationScore,
    soulScore,
    personalityScore,
    strengths,
    challenges,
    advice,
    quote,
  ];
}
