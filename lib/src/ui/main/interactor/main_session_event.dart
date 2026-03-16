import 'dart:async';

import 'package:equatable/equatable.dart';

class MainSessionEvent extends Equatable {
  const MainSessionEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class MainSessionInitializeRequested extends MainSessionEvent {
  const MainSessionInitializeRequested({required this.completer});

  final Completer<void> completer;
}

final class MainSessionLoginRequested extends MainSessionEvent {
  const MainSessionLoginRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.completer,
  });

  final String email;
  final String password;
  final String name;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[email, password, name];
}

final class MainSessionRegisterRequested extends MainSessionEvent {
  const MainSessionRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.completer,
  });

  final String email;
  final String password;
  final String name;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[email, password, name];
}

final class MainSessionLogoutRequested extends MainSessionEvent {
  const MainSessionLogoutRequested({required this.completer});

  final Completer<void> completer;
}

final class MainSessionProfileAdded extends MainSessionEvent {
  const MainSessionProfileAdded({
    required this.name,
    required this.birthDate,
    required this.completer,
  });

  final String name;
  final DateTime birthDate;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[name, birthDate];
}

final class MainSessionProfileSwitched extends MainSessionEvent {
  const MainSessionProfileSwitched({
    required this.profileId,
    required this.completer,
  });

  final String profileId;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[profileId];
}

final class MainSessionProfileUpdated extends MainSessionEvent {
  const MainSessionProfileUpdated({
    required this.profileId,
    required this.name,
    required this.birthDate,
    required this.completer,
  });

  final String profileId;
  final String name;
  final DateTime birthDate;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[profileId, name, birthDate];
}

final class MainSessionProfileRemoved extends MainSessionEvent {
  const MainSessionProfileRemoved({
    required this.profileId,
    required this.completer,
  });

  final String profileId;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[profileId];
}

final class MainSessionCompareProfileAdded extends MainSessionEvent {
  const MainSessionCompareProfileAdded({
    required this.name,
    required this.relation,
    required this.birthDate,
    required this.completer,
  });

  final String name;
  final String relation;
  final DateTime birthDate;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[name, relation, birthDate];
}

final class MainSessionCompareProfileSelected extends MainSessionEvent {
  const MainSessionCompareProfileSelected({
    required this.profileId,
    required this.completer,
  });

  final String profileId;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[profileId];
}

final class MainSessionSoulPointsAdded extends MainSessionEvent {
  const MainSessionSoulPointsAdded({
    required this.amount,
    required this.completer,
  });

  final int amount;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[amount];
}

final class MainSessionSoulPointsDeducted extends MainSessionEvent {
  const MainSessionSoulPointsDeducted({
    required this.amount,
    required this.completer,
  });

  final int amount;
  final Completer<bool> completer;

  @override
  List<Object?> get props => <Object?>[amount];
}

final class MainSessionCheckedIn extends MainSessionEvent {
  const MainSessionCheckedIn({required this.completer});

  final Completer<void> completer;
}

final class MainSessionInteractionTracked extends MainSessionEvent {
  const MainSessionInteractionTracked(this.page);

  final String page;

  @override
  List<Object?> get props => <Object?>[page];
}

final class MainSessionPageInteractionReset extends MainSessionEvent {
  const MainSessionPageInteractionReset(this.page);

  final String page;

  @override
  List<Object?> get props => <Object?>[page];
}

final class MainSessionTimeLifeRefreshRequested extends MainSessionEvent {
  const MainSessionTimeLifeRefreshRequested({
    required this.now,
    required this.force,
    required this.completer,
  });

  final DateTime? now;
  final bool force;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[now, force];
}
