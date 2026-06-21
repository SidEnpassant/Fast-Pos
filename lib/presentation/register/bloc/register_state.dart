import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, submitting, success, failure }
enum RegisterOtpStatus { none, sending, sent, verifying, verified, error }

class RegisterState extends Equatable {
  const RegisterState({
    this.status = RegisterStatus.initial,
    this.otpStatus = RegisterOtpStatus.none,
    this.isEmailVerified = false,
    this.errorMessage,
    this.obscurePassword = true,
    this.signatureLocalPath,
    this.successEmail,
  });

  final RegisterStatus status;
  final RegisterOtpStatus otpStatus;
  final bool isEmailVerified;
  final String? errorMessage;
  final bool obscurePassword;
  final String? signatureLocalPath;
  final String? successEmail;

  RegisterState copyWith({
    RegisterStatus? status,
    RegisterOtpStatus? otpStatus,
    bool? isEmailVerified,
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
      otpStatus: otpStatus ?? this.otpStatus,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
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
        otpStatus,
        isEmailVerified,
        errorMessage,
        obscurePassword,
        signatureLocalPath,
        successEmail,
      ];
}
