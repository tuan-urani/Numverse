import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/user_profile.dart';

sealed class ComparisonResultEvent extends Equatable {
  const ComparisonResultEvent();
}

final class ComparisonResultLoaded extends ComparisonResultEvent {
  const ComparisonResultLoaded({
    required this.selfProfile,
    required this.targetProfile,
    required this.languageCode,
  });

  final UserProfile? selfProfile;
  final ComparisonProfile? targetProfile;
  final String languageCode;

  @override
  List<Object?> get props => <Object?>[
    selfProfile,
    targetProfile,
    languageCode,
  ];
}
