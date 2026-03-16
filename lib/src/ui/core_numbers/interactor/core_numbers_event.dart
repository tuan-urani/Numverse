import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';

sealed class CoreNumbersEvent extends Equatable {
  const CoreNumbersEvent();
}

final class CoreNumbersProfileSynced extends CoreNumbersEvent {
  const CoreNumbersProfileSynced({
    required this.profile,
    required this.languageCode,
    required this.lifeBasedSnapshot,
  });

  final UserProfile? profile;
  final String languageCode;
  final ProfileLifeBasedSnapshot? lifeBasedSnapshot;

  @override
  List<Object?> get props => <Object?>[
    profile,
    languageCode,
    lifeBasedSnapshot,
  ];
}
