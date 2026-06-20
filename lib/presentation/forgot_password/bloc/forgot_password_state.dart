import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus { initial, loading, success, failure }

enum ForgotPasswordStep { email, otp, newPassword, success }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.errorMessage,
  });

  final ForgotPasswordStatus status;
  final ForgotPasswordStep step;
  final String email;
  final String? errorMessage;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    ForgotPasswordStep? step,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      step: step ?? this.step,
      email: email ?? this.email,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, step, email, errorMessage];
}
