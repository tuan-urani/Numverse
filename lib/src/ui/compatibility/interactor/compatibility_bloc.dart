import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_constants.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_event.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_state.dart';

class CompatibilityBloc extends Bloc<CompatibilityEvent, CompatibilityState> {
  CompatibilityBloc() : super(CompatibilityState.initial()) {
    on<CompatibilityCompareProfileAdded>(_onCompareProfileAdded);
    on<CompatibilityCompareProfileSelected>(_onCompareProfileSelected);
  }

  static const int comparisonCost = kCompatibilityComparisonCost;

  void addCompareProfile({
    required String name,
    required String relation,
    required DateTime birthDate,
  }) {
    add(
      CompatibilityCompareProfileAdded(
        name: name,
        relation: relation,
        birthDate: birthDate,
      ),
    );
  }

  void _onCompareProfileAdded(
    CompatibilityCompareProfileAdded event,
    Emitter<CompatibilityState> emit,
  ) {
    final ComparisonProfile profile = ComparisonProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name.trim(),
      relation: event.relation.trim(),
      birthDate: event.birthDate,
      lifePathNumber: NumerologyHelper.getLifePathNumber(event.birthDate),
    );

    emit(
      state.copyWith(
        compareProfiles: <ComparisonProfile>[...state.compareProfiles, profile],
        selectedProfileId: profile.id,
      ),
    );
  }

  void selectCompareProfile(String profileId) {
    add(CompatibilityCompareProfileSelected(profileId));
  }

  void _onCompareProfileSelected(
    CompatibilityCompareProfileSelected event,
    Emitter<CompatibilityState> emit,
  ) {
    final String profileId = event.profileId;
    if (!state.compareProfiles.any(
      (ComparisonProfile e) => e.id == profileId,
    )) {
      return;
    }
    emit(state.copyWith(selectedProfileId: profileId));
  }
}
