import 'package:equatable/equatable.dart';

sealed class UniversalDayEvent extends Equatable {
  const UniversalDayEvent();
}

final class UniversalDayRefreshed extends UniversalDayEvent {
  const UniversalDayRefreshed();

  @override
  List<Object?> get props => <Object?>[];
}
