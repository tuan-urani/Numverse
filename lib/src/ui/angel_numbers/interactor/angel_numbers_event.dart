import 'package:equatable/equatable.dart';

sealed class AngelNumbersEvent extends Equatable {
  const AngelNumbersEvent();
}

final class AngelNumbersSearchTextChanged extends AngelNumbersEvent {
  const AngelNumbersSearchTextChanged(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class AngelNumbersSearchRequested extends AngelNumbersEvent {
  const AngelNumbersSearchRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AngelNumbersQuickSearchRequested extends AngelNumbersEvent {
  const AngelNumbersQuickSearchRequested(this.number);

  final String number;

  @override
  List<Object?> get props => <Object?>[number];
}
