import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/main/interactor/main_navigation_event.dart';

class MainNavigationBloc extends Bloc<MainNavigationEvent, int> {
  MainNavigationBloc() : super(0) {
    on<MainNavigationTabSelected>(_onTabSelected);
  }

  void selectTab(int index) {
    add(MainNavigationTabSelected(index));
  }

  void _onTabSelected(MainNavigationTabSelected event, Emitter<int> emit) {
    final int index = event.index;
    if (index == state) {
      return;
    }
    emit(index);
  }
}
