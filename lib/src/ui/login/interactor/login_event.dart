import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();
}

final class LoginEmailUpdated extends LoginEvent {
  const LoginEmailUpdated(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class LoginPasswordUpdated extends LoginEvent {
  const LoginPasswordUpdated(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.onDone, required this.completer});

  final Future<void> Function() onDone;
  final Completer<void> completer;

  @override
  List<Object?> get props => <Object?>[onDone];
}
