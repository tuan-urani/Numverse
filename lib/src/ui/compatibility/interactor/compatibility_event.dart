import 'package:equatable/equatable.dart';

sealed class CompatibilityEvent extends Equatable {
  const CompatibilityEvent();
}

final class CompatibilityCompareProfileAdded extends CompatibilityEvent {
  const CompatibilityCompareProfileAdded({
    required this.name,
    required this.relation,
    required this.birthDate,
  });

  final String name;
  final String relation;
  final DateTime birthDate;

  @override
  List<Object?> get props => <Object?>[name, relation, birthDate];
}

final class CompatibilityCompareProfileSelected extends CompatibilityEvent {
  const CompatibilityCompareProfileSelected(this.profileId);

  final String profileId;

  @override
  List<Object?> get props => <Object?>[profileId];
}
