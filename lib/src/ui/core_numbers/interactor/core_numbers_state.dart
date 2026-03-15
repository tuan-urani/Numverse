import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';

class CoreNumbersState extends Equatable {
  const CoreNumbersState({
    required this.hasProfile,
    required this.lifePathNumber,
    required this.soulUrgeNumber,
    required this.expressionNumber,
    required this.missionNumber,
    required this.lifePathContent,
    required this.soulUrgeContent,
    required this.expressionContent,
    required this.missionContent,
  });

  factory CoreNumbersState.initial() {
    return CoreNumbersState(
      hasProfile: false,
      lifePathNumber: 1,
      soulUrgeNumber: 1,
      expressionNumber: 1,
      missionNumber: 1,
      lifePathContent: const CoreNumberContent(
        title: '',
        description: '',
        interpretation: '',
        keywords: <String>[],
      ),
      soulUrgeContent: const CoreNumberContent(
        title: '',
        description: '',
        interpretation: '',
        keywords: <String>[],
      ),
      expressionContent: const CoreNumberContent(
        title: '',
        description: '',
        interpretation: '',
        keywords: <String>[],
      ),
      missionContent: const CoreNumberContent(
        title: '',
        description: '',
        interpretation: '',
        keywords: <String>[],
      ),
    );
  }

  final bool hasProfile;
  final int lifePathNumber;
  final int soulUrgeNumber;
  final int expressionNumber;
  final int missionNumber;
  final CoreNumberContent lifePathContent;
  final CoreNumberContent soulUrgeContent;
  final CoreNumberContent expressionContent;
  final CoreNumberContent missionContent;

  CoreNumbersState copyWith({
    bool? hasProfile,
    int? lifePathNumber,
    int? soulUrgeNumber,
    int? expressionNumber,
    int? missionNumber,
    CoreNumberContent? lifePathContent,
    CoreNumberContent? soulUrgeContent,
    CoreNumberContent? expressionContent,
    CoreNumberContent? missionContent,
  }) {
    return CoreNumbersState(
      hasProfile: hasProfile ?? this.hasProfile,
      lifePathNumber: lifePathNumber ?? this.lifePathNumber,
      soulUrgeNumber: soulUrgeNumber ?? this.soulUrgeNumber,
      expressionNumber: expressionNumber ?? this.expressionNumber,
      missionNumber: missionNumber ?? this.missionNumber,
      lifePathContent: lifePathContent ?? this.lifePathContent,
      soulUrgeContent: soulUrgeContent ?? this.soulUrgeContent,
      expressionContent: expressionContent ?? this.expressionContent,
      missionContent: missionContent ?? this.missionContent,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    hasProfile,
    lifePathNumber,
    soulUrgeNumber,
    expressionNumber,
    missionNumber,
    lifePathContent,
    soulUrgeContent,
    expressionContent,
    missionContent,
  ];
}
