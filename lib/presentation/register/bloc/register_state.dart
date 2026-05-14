import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, submitting, success, failure }

class RegisterState extends Equatable {
  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errorMessage,
    this.obscurePassword = true,
    this.signatureLocalPath,
    this.successEmail,
  });

  final RegisterStatus status;
  final String? errorMessage;
  final bool obscurePassword;
  final String? signatureLocalPath;
  final String? successEmail;

  RegisterState copyWith({
    RegisterStatus? status,
    String? errorMessage,
    bool? obscurePassword,
    String? signatureLocalPath,
    String? successEmail,
    bool clearError = false,
    bool clearSignature = false,
    bool clearSuccessEmail = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      obscurePassword: obscurePassword ?? this.obscurePassword,
      signatureLocalPath: clearSignature
          ? null
          : (signatureLocalPath ?? this.signatureLocalPath),
      successEmail:
          clearSuccessEmail ? null : (successEmail ?? this.successEmail),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        obscurePassword,
        signatureLocalPath,
        successEmail,
      ];
}
