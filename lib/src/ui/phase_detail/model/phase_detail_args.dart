import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';

enum PhaseDetailType { pinnacle, challenge }

class PhaseDetailArgs extends Equatable {
  const PhaseDetailArgs({
    required this.type,
    required this.index,
    required this.number,
    required this.period,
    required this.status,
    required this.theme,
    required this.description,
    required this.opportunities,
    required this.advice,
  });

  final PhaseDetailType type;
  final int index;
  final int number;
  final String period;
  final LifeCycleStatus status;
  final String theme;
  final String description;
  final String opportunities;
  final String advice;

  String get title {
    return switch (type) {
      PhaseDetailType.pinnacle => 'Cuộc đời ${index + 1}',
      PhaseDetailType.challenge => 'Thử thách ${index + 1}',
    };
  }

  String get opportunitiesTitle {
    return switch (type) {
      PhaseDetailType.pinnacle => 'Cơ hội phát triển',
      PhaseDetailType.challenge => 'Cơ hội vượt qua',
    };
  }

  @override
  List<Object?> get props => <Object?>[
    type,
    index,
    number,
    period,
    status,
    theme,
    description,
    opportunities,
    advice,
  ];
}

class PhaseDetailStageArgs extends Equatable {
  const PhaseDetailStageArgs({
    required this.index,
    required this.stageTitle,
    required this.periodLabel,
    required this.status,
    required this.pinnacle,
    required this.challenge,
  });

  final int index;
  final String stageTitle;
  final String periodLabel;
  final LifeCycleStatus status;
  final PhaseDetailArgs pinnacle;
  final PhaseDetailArgs challenge;

  String get title => 'Giai đoạn ${index + 1}';

  @override
  List<Object?> get props => <Object?>[
    index,
    stageTitle,
    periodLabel,
    status,
    pinnacle,
    challenge,
  ];
}
