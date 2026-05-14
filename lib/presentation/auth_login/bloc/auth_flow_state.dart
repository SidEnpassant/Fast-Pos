import 'package:equatable/equatable.dart';

enum AuthFlowStatus { unknown, authenticated, unauthenticated }

class AuthFlowState extends Equatable {
  const AuthFlowState({
    this.status = AuthFlowStatus.unknown,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthFlowStatus status;
  final bool isSubmitting;
  final String? errorMessage;

  AuthFlowState copyWith({
    AuthFlowStatus? status,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthFlowState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, isSubmitting, errorMessage];
}
