import 'package:equatable/equatable.dart';

sealed class DailyMessageEvent extends Equatable {
  const DailyMessageEvent();
}

final class DailyMessageRefreshed extends DailyMessageEvent {
  const DailyMessageRefreshed();

  @override
  List<Object?> get props => <Object?>[];
}
