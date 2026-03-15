import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/comparison_profile.dart';

class CompatibilityState extends Equatable {
  const CompatibilityState({
    required this.compareProfiles,
    required this.selectedProfileId,
  });

  factory CompatibilityState.initial() {
    return const CompatibilityState(
      compareProfiles: <ComparisonProfile>[],
      selectedProfileId: null,
    );
  }

  final List<ComparisonProfile> compareProfiles;
  final String? selectedProfileId;

  bool get hasProfiles => compareProfiles.isNotEmpty;

  ComparisonProfile? get selectedProfile {
    if (selectedProfileId == null) {
      return null;
    }
    for (final ComparisonProfile profile in compareProfiles) {
      if (profile.id == selectedProfileId) {
        return profile;
      }
    }
    return null;
  }

  CompatibilityState copyWith({
    List<ComparisonProfile>? compareProfiles,
    String? selectedProfileId,
    bool clearSelectedProfile = false,
  }) {
    return CompatibilityState(
      compareProfiles: compareProfiles ?? this.compareProfiles,
      selectedProfileId: clearSelectedProfile
          ? null
          : selectedProfileId ?? this.selectedProfileId,
    );
  }

  @override
  List<Object?> get props => <Object?>[compareProfiles, selectedProfileId];
}
