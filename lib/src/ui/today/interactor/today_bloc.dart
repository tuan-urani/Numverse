import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/today/interactor/today_event.dart';
import 'package:test/src/ui/today/interactor/today_state.dart';

class TodayBloc extends Bloc<TodayEvent, TodayState> {
  TodayBloc() : super(TodayState.initial()) {
    on<TodayTabSelected>(_onTabSelected);
  }

  void selectTab(TodayTab tab) {
    add(TodayTabSelected(tab));
  }

  void _onTabSelected(TodayTabSelected event, Emitter<TodayState> emit) {
    final TodayTab tab = event.tab;
    if (state.tab == tab) {
      return;
    }
    emit(state.copyWith(tab: tab));
  }
}
