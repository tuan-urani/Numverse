import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/help/interactor/help_event.dart';
import 'package:test/src/ui/help/interactor/help_state.dart';

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  HelpBloc() : super(HelpState.initial()) {
    on<HelpFaqToggled>(_onFaqToggled);
  }

  void toggleFaq(int id) {
    add(HelpFaqToggled(id));
  }

  void _onFaqToggled(HelpFaqToggled event, Emitter<HelpState> emit) {
    emit(
      state.copyWith(
        expandedFaqId: state.expandedFaqId == event.id ? null : event.id,
        clearExpandedFaqId: state.expandedFaqId == event.id,
      ),
    );
  }
}
