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
      selfName: 'Nguyen Van Minh',
      selfDate: '12/08/1998',
      selfLifePath: 7,
      selfSoul: 2,
      selfPersonality: 5,
      selfExpression: 3,
      targetName: 'Lan',
      targetRelation: 'lover',
      targetDate: '15/03/1999',
      targetLifePath: 9,
      targetSoul: 6,
      targetPersonality: 3,
      targetExpression: 6,
      overallScore: 85,
      coreScore: 88,
      communicationScore: 82,
      soulScore: 90,
      personalityScore: 78,
      strengths: <String>[
        'Hai bạn có nền tảng đồng điệu tích cực.',
        'Giao tiếp có tiềm năng đi vào chiều sâu.',
        'Có khả năng hỗ trợ nhau khi khó khăn.',
        'Phù hợp đồng hành mục tiêu dài hạn.',
      ],
      challenges: <String>[
        'Dễ kỳ vọng cao khi kết nối đang thuận lợi.',
        'Có thể bỏ qua mâu thuẫn nhỏ tích tụ.',
        'Nhịp cảm xúc đôi lúc lệch nhau.',
      ],
      advice: <String>[
        'Đối thoại định kỳ để giữ kết nối rõ ràng.',
        'Thống nhất mục tiêu chung theo từng giai đoạn.',
        'Tôn trọng ranh giới và không gian riêng.',
        'Giải quyết mâu thuẫn sớm, không để kéo dài.',
      ],
      quote: 'Sự hòa hợp bền vững đến từ lựa chọn đồng hành mỗi ngày.',
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
