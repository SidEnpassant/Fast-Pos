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

final class ForgotPasswordOtpSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordOtpSubmitted(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];
}

final class ForgotPasswordNewPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordNewPasswordSubmitted(this.newPassword);

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}

final class ForgotPasswordBackRequested extends ForgotPasswordEvent {
  const ForgotPasswordBackRequested();
}
