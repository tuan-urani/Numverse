import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/reading/interactor/reading_event.dart';
import 'package:test/src/ui/reading/interactor/reading_state.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  ReadingBloc() : super(ReadingState.initial()) {
    on<ReadingProfileDialogOpened>(_onProfileDialogOpened);
    on<ReadingProfileDialogClosed>(_onProfileDialogClosed);
  }

  void openProfileDialog() {
    add(const ReadingProfileDialogOpened());
  }

  void _onProfileDialogOpened(
    ReadingProfileDialogOpened event,
    Emitter<ReadingState> emit,
  ) {
    if (state.isProfileDialogOpen) {
      return;
    }
    emit(state.copyWith(isProfileDialogOpen: true));
  }

  void closeProfileDialog() {
    add(const ReadingProfileDialogClosed());
  }

  void _onProfileDialogClosed(
    ReadingProfileDialogClosed event,
    Emitter<ReadingState> emit,
  ) {
    if (!state.isProfileDialogOpen) {
      return;
    }
    emit(state.copyWith(isProfileDialogOpen: false));
  }
}
