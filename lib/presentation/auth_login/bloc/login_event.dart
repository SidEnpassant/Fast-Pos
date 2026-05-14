import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

final class LoginObscurePasswordToggled extends LoginEvent {
  const LoginObscurePasswordToggled();
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class LoginUiMessageConsumed extends LoginEvent {
  const LoginUiMessageConsumed();
}
