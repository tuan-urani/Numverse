import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({
    required this.email,
    required this.password,
    required this.submitting,
  });

  factory LoginState.initial() =>
      const LoginState(email: '', password: '', submitting: false);

  final String email;
  final String password;
  final bool submitting;

  bool get canSubmit => email.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginState copyWith({String? email, String? password, bool? submitting}) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => <Object?>[email, password, submitting];
}
