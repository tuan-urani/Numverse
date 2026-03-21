import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/core_numbers/interactor/core_numbers_event.dart';
import 'package:test/src/ui/core_numbers/interactor/core_numbers_state.dart';

class CoreNumbersBloc extends Bloc<CoreNumbersEvent, CoreNumbersState> {
  CoreNumbersBloc({required INumerologyContentRepository contentRepository})
    : _contentRepository = contentRepository,
      super(CoreNumbersState.initial()) {
    on<CoreNumbersProfileSynced>(_onProfileSynced);
  }

  final INumerologyContentRepository _contentRepository;

  void syncProfile(
    UserProfile? profile, {
    required String languageCode,
    ProfileLifeBasedSnapshot? lifeBasedSnapshot,
  }) {
    add(
      CoreNumbersProfileSynced(
        profile: profile,
        languageCode: languageCode,
        lifeBasedSnapshot: lifeBasedSnapshot,
      ),
    );
  }

  void _onProfileSynced(
    CoreNumbersProfileSynced event,
    Emitter<CoreNumbersState> emit,
  ) {
    final UserProfile? profile = event.profile;
    final String languageCode = event.languageCode;
    if (profile == null) {
      emit(CoreNumbersState.initial());
      return;
    }

    final int lifePathNumber =
        event.lifeBasedSnapshot?.valueOf(
          ProfileLifeBasedSnapshot.lifePathMetric,
        ) ??
        NumerologyHelper.getLifePathNumber(profile.birthDate);
    final int soulUrgeNumber =
        event.lifeBasedSnapshot?.valueOf(
          ProfileLifeBasedSnapshot.soulUrgeMetric,
        ) ??
        NumerologyHelper.getSoulUrgeNumber(profile.name);
    final int expressionNumber =
        event.lifeBasedSnapshot?.valueOf(
          ProfileLifeBasedSnapshot.expressionMetric,
        ) ??
        NumerologyHelper.getExpressionNumber(profile.name);
    final int missionNumber =
        event.lifeBasedSnapshot?.valueOf(
          ProfileLifeBasedSnapshot.missionMetric,
        ) ??
        NumerologyHelper.getMissionNumber(profile.birthDate, profile.name);

    emit(
      state.copyWith(
        hasProfile: true,
        lifePathNumber: lifePathNumber,
        soulUrgeNumber: soulUrgeNumber,
        expressionNumber: expressionNumber,
        missionNumber: missionNumber,
        lifePathContent: _contentRepository.getLifePathNumberContent(
          number: lifePathNumber,
          languageCode: languageCode,
        ),
        soulUrgeContent: _contentRepository.getSoulUrgeNumberContent(
          number: soulUrgeNumber,
          languageCode: languageCode,
        ),
        expressionContent: _contentRepository.getExpressionNumberContent(
          number: expressionNumber,
          languageCode: languageCode,
        ),
        missionContent: _contentRepository.getMissionNumberContent(
          number: missionNumber,
          languageCode: languageCode,
        ),
      ),
    );
  }
}
