import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';

class LifePathState extends Equatable {
  const LifePathState({
    required this.hasProfile,
    required this.currentAge,
    required this.pinnacles,
    required this.challenges,
    required this.pinnacleContentByNumber,
    required this.challengeContentByNumber,
    required this.expandedPinnacles,
    required this.expandedChallenges,
  });

  factory LifePathState.initial() {
    return const LifePathState(
      hasProfile: false,
      currentAge: 0,
      pinnacles: <PinnacleCycle>[],
      challenges: <ChallengeCycle>[],
      pinnacleContentByNumber: <int, LifeCycleContent>{},
      challengeContentByNumber: <int, LifeCycleContent>{},
      expandedPinnacles: true,
      expandedChallenges: false,
    );
  }

  final bool hasProfile;
  final int currentAge;
  final List<PinnacleCycle> pinnacles;
  final List<ChallengeCycle> challenges;
  final Map<int, LifeCycleContent> pinnacleContentByNumber;
  final Map<int, LifeCycleContent> challengeContentByNumber;
  final bool expandedPinnacles;
  final bool expandedChallenges;

  LifePathState copyWith({
    bool? hasProfile,
    int? currentAge,
    List<PinnacleCycle>? pinnacles,
    List<ChallengeCycle>? challenges,
    Map<int, LifeCycleContent>? pinnacleContentByNumber,
    Map<int, LifeCycleContent>? challengeContentByNumber,
    bool? expandedPinnacles,
    bool? expandedChallenges,
  }) {
    return LifePathState(
      hasProfile: hasProfile ?? this.hasProfile,
      currentAge: currentAge ?? this.currentAge,
      pinnacles: pinnacles ?? this.pinnacles,
      challenges: challenges ?? this.challenges,
      pinnacleContentByNumber:
          pinnacleContentByNumber ?? this.pinnacleContentByNumber,
      challengeContentByNumber:
          challengeContentByNumber ?? this.challengeContentByNumber,
      expandedPinnacles: expandedPinnacles ?? this.expandedPinnacles,
      expandedChallenges: expandedChallenges ?? this.expandedChallenges,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    hasProfile,
    currentAge,
    pinnacles,
    challenges,
    pinnacleContentByNumber,
    challengeContentByNumber,
    expandedPinnacles,
    expandedChallenges,
  ];
}
