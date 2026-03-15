import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/user_profile.dart';

sealed class CoreNumbersEvent extends Equatable {
  const CoreNumbersEvent();
}

final class CoreNumbersProfileSynced extends CoreNumbersEvent {
  const CoreNumbersProfileSynced({
    required this.profile,
    required this.languageCode,
  });

  final UserProfile? profile;
  final String languageCode;

  @override
  List<Object?> get props => <Object?>[profile, languageCode];
}
