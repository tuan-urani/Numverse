import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/user_profile.dart';

sealed class LifePathEvent extends Equatable {
  const LifePathEvent();
}

final class LifePathProfileSynced extends LifePathEvent {
  const LifePathProfileSynced({
    required this.profile,
    required this.languageCode,
  });

  final UserProfile? profile;
  final String languageCode;

  @override
  List<Object?> get props => <Object?>[profile, languageCode];
}

final class LifePathPinnaclesToggled extends LifePathEvent {
  const LifePathPinnaclesToggled();

  @override
  List<Object?> get props => <Object?>[];
}

final class LifePathChallengesToggled extends LifePathEvent {
  const LifePathChallengesToggled();

  @override
  List<Object?> get props => <Object?>[];
}
