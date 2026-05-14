import 'package:bloc/bloc.dart';
import 'package:inventopos/application/auth/login_credentials_validator.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/domain/auth/auth_operation_failure.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._signIn) : super(const LoginState()) {
    on<LoginObscurePasswordToggled>(_onObscureToggled);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginUiMessageConsumed>(_onMessageConsumed);
  }

  final SignInUseCase _signIn;

  void _onObscureToggled(
    LoginObscurePasswordToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final emailErr = LoginCredentialsValidator.email(event.email);
    final passErr = LoginCredentialsValidator.password(event.password);
    if (emailErr != null || passErr != null) {
      emit(
        LoginState(
          obscurePassword: state.obscurePassword,
          emailError: emailErr,
          passwordError: passErr,
        ),
      );
      return;
    }

    emit(
      LoginState(
        obscurePassword: state.obscurePassword,
        isSubmitting: true,
      ),
    );

    try {
      await _signIn(
        email: event.email.trim(),
        password: event.password,
      );
      emit(
        LoginState(
          obscurePassword: state.obscurePassword,
          isSubmitting: false,
        ),
      );
    } on AuthOperationFailure catch (e) {
      emit(
        LoginState(
          obscurePassword: state.obscurePassword,
          isSubmitting: false,
          errorMessage: _mapLoginError(e.message),
        ),
      );
    } catch (e) {
      emit(
        LoginState(
          obscurePassword: state.obscurePassword,
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onMessageConsumed(
    LoginUiMessageConsumed event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(clearErrorMessage: true));
  }

  String _mapLoginError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Wrong email or password';
    }
    return message.isNotEmpty ? message : 'Wrong email or password';
  }
}
