import 'package:equatable/equatable.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class ForgotPasswordUiCleared extends ForgotPasswordEvent {
  const ForgotPasswordUiCleared();
}
