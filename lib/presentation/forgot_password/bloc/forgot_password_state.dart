import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus { initial, loading, success, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
  });

  final ForgotPasswordStatus status;
  final String? errorMessage;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
