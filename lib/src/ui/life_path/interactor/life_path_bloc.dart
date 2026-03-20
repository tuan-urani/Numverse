import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/life_path/interactor/life_path_event.dart';
import 'package:test/src/ui/life_path/interactor/life_path_state.dart';

class LifePathBloc extends Bloc<LifePathEvent, LifePathState> {
  LifePathBloc({required INumerologyContentRepository contentRepository})
    : _contentRepository = contentRepository,
      super(LifePathState.initial()) {
    on<LifePathProfileSynced>(_onProfileSynced);
    on<LifePathPinnaclesToggled>(_onPinnaclesToggled);
    on<LifePathChallengesToggled>(_onChallengesToggled);
  }

  final INumerologyContentRepository _contentRepository;

  void syncProfile(UserProfile? profile, {required String languageCode}) {
    add(LifePathProfileSynced(profile: profile, languageCode: languageCode));
  }

  void _onProfileSynced(
    LifePathProfileSynced event,
    Emitter<LifePathState> emit,
  ) {
    final UserProfile? profile = event.profile;
    final String languageCode = event.languageCode;
    if (profile == null) {
      emit(LifePathState.initial());
      return;
    }

    final int currentAge = NumerologyHelper.calculateAge(profile.birthDate);
    final pinnacles = NumerologyHelper.calculatePinnacles(
      profile.birthDate,
      currentAge,
    );
    final challenges = NumerologyHelper.calculateChallenges(
      profile.birthDate,
      currentAge,
    );
    final Set<int> seenPinnacle = <int>{};
    final Set<int> seenChallenge = <int>{};
    final Map<int, LifeCycleContent> pinnacleContentByNumber =
        <int, LifeCycleContent>{};
    final Map<int, LifeCycleContent> challengeContentByNumber =
        <int, LifeCycleContent>{};
    for (final cycle in pinnacles) {
      if (seenPinnacle.contains(cycle.number)) {
        continue;
      }
      seenPinnacle.add(cycle.number);
      pinnacleContentByNumber[cycle.number] = _contentRepository
          .getLifePinnacleContent(
            number: cycle.number,
            languageCode: languageCode,
          );
    }
    for (final cycle in challenges) {
      if (seenChallenge.contains(cycle.number)) {
        continue;
      }
      seenChallenge.add(cycle.number);
      challengeContentByNumber[cycle.number] = _contentRepository
          .getLifeChallengeContent(
            number: cycle.number,
            languageCode: languageCode,
          );
    }

    emit(
      state.copyWith(
        hasProfile: true,
        currentAge: currentAge,
        pinnacles: pinnacles,
        challenges: challenges,
        pinnacleContentByNumber: pinnacleContentByNumber,
        challengeContentByNumber: challengeContentByNumber,
      ),
    );
  }

  void togglePinnacles() {
    add(const LifePathPinnaclesToggled());
  }

  void _onPinnaclesToggled(
    LifePathPinnaclesToggled event,
    Emitter<LifePathState> emit,
  ) {
    final bool willExpand = !state.expandedPinnacles;
    emit(
      state.copyWith(expandedPinnacles: willExpand, expandedChallenges: false),
    );
  }

  void toggleChallenges() {
    add(const LifePathChallengesToggled());
  }

  void _onChallengesToggled(
    LifePathChallengesToggled event,
    Emitter<LifePathState> emit,
  ) {
    final bool willExpand = !state.expandedChallenges;
    emit(
      state.copyWith(expandedChallenges: willExpand, expandedPinnacles: false),
    );
  }
}
