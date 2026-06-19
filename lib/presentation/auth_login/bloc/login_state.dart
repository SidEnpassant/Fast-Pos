import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.isGoogleSigningIn = false,
    this.emailError,
    this.passwordError,
    this.errorMessage,
  });

  final bool obscurePassword;
  final bool isSubmitting;
  final bool isGoogleSigningIn;
  final String? emailError;
  final String? passwordError;
  final String? errorMessage;

  LoginState copyWith({
    bool? obscurePassword,
    bool? isSubmitting,
    bool? isGoogleSigningIn,
    String? emailError,
    String? passwordError,
    String? errorMessage,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearErrorMessage = false,
  }) {
    return LoginState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isGoogleSigningIn: isGoogleSigningIn ?? this.isGoogleSigningIn,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        obscurePassword,
        isSubmitting,
        isGoogleSigningIn,
        emailError,
        passwordError,
        errorMessage,
      ];
}
