import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/login/interactor/login_event.dart';
import 'package:test/src/ui/login/interactor/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<LoginEmailUpdated>(_onEmailUpdated);
    on<LoginPasswordUpdated>(_onPasswordUpdated);
    on<LoginSubmitted>(_onSubmitted);
  }

  void updateEmail(String value) => add(LoginEmailUpdated(value));

  void updatePassword(String value) => add(LoginPasswordUpdated(value));

  void _onEmailUpdated(LoginEmailUpdated event, Emitter<LoginState> emit) {
    emit(state.copyWith(email: event.value));
  }

  void _onPasswordUpdated(
    LoginPasswordUpdated event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.value));
  }

  Future<void> submit(Future<void> Function() onDone) async {
    final Completer<void> completer = Completer<void>();
    add(LoginSubmitted(onDone: onDone, completer: completer));
    await completer.future;
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.canSubmit || state.submitting) {
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
      return;
    }
    emit(state.copyWith(submitting: true));
    try {
      await event.onDone();
      if (!event.completer.isCompleted) {
        event.completer.complete();
      }
    } catch (error, stackTrace) {
      if (!event.completer.isCompleted) {
        event.completer.completeError(error, stackTrace);
      }
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }
}
