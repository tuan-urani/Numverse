import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';

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

final class MainSessionCompatibilityHistorySaved extends MainSessionEvent {
  const MainSessionCompatibilityHistorySaved({
    required this.item,
    required this.completer,
  });

  final CompatibilityHistoryItem item;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[item];
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

final class MainSessionAdRewardClaimed extends MainSessionEvent {
  const MainSessionAdRewardClaimed({
    required this.amount,
    required this.placementCode,
    required this.requestId,
    required this.completer,
  });

  final int amount;
  final String placementCode;
  final String? requestId;
  final Completer<bool> completer;

  @override
  List<Object?> get props => <Object?>[amount, placementCode, requestId];
}

final class MainSessionAdRewardStatusRefreshRequested extends MainSessionEvent {
  const MainSessionAdRewardStatusRefreshRequested({
    required this.placementCode,
    required this.completer,
  });

  final String placementCode;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[placementCode];
}

final class MainSessionSoulPointsDeducted extends MainSessionEvent {
  const MainSessionSoulPointsDeducted({
    required this.amount,
    required this.sourceType,
    required this.metadata,
    required this.requestId,
    required this.completer,
  });

  final int amount;
  final String sourceType;
  final Map<String, dynamic> metadata;
  final String requestId;
  final Completer<bool> completer;

  @override
  List<Object?> get props => <Object?>[amount, sourceType, requestId];
}

final class MainSessionSoulPointsSynced extends MainSessionEvent {
  const MainSessionSoulPointsSynced({
    required this.soulPoints,
    required this.completer,
  });

  final int soulPoints;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[soulPoints];
}

final class MainSessionCheckedIn extends MainSessionEvent {
  const MainSessionCheckedIn({required this.completer});

  final Completer<void> completer;
}

final class MainSessionCheckInCelebrationConsumed extends MainSessionEvent {
  const MainSessionCheckInCelebrationConsumed({required this.eventId});

  final int eventId;

  @override
  List<Object?> get props => <Object?>[eventId];
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
