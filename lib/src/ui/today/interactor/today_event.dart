import 'package:equatable/equatable.dart';

import 'package:test/src/ui/today/interactor/today_state.dart';

sealed class TodayEvent extends Equatable {
  const TodayEvent();
}

final class TodayTabSelected extends TodayEvent {
  const TodayTabSelected(this.tab);

  final TodayTab tab;

  @override
  List<Object?> get props => <Object?>[tab];
}
