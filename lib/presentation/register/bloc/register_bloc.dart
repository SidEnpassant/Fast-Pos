import 'package:bloc/bloc.dart';
import 'package:inventopos/application/registration/register_account_use_case.dart';
import 'package:inventopos/domain/registration/registration_result.dart';
import 'package:inventopos/presentation/register/bloc/register_event.dart';
import 'package:inventopos/presentation/register/bloc/register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(this._registerAccount) : super(const RegisterState()) {
    on<RegisterPasswordVisibilityToggled>(_onTogglePassword);
    on<RegisterSignaturePathChanged>(_onSignaturePath);
    on<RegisterSubmitted>(_onSubmitted);
  }

  final RegisterAccountUseCase _registerAccount;

  void _onTogglePassword(
    RegisterPasswordVisibilityToggled event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void _onSignaturePath(
    RegisterSignaturePathChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(signatureLocalPath: event.path));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RegisterStatus.submitting,
        clearError: true,
        clearSuccessEmail: true,
      ),
    );
    final result = await _registerAccount(event.payload);
    switch (result.kind) {
      case RegistrationResultKind.success:
        emit(
          state.copyWith(
            status: RegisterStatus.success,
            successEmail: event.payload.email.trim(),
          ),
        );
      case RegistrationResultKind.rejectedInvalid:
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            errorMessage: result.message ??
                'Sign up was rejected. Check email and password.',
          ),
        );
      case RegistrationResultKind.rejectedNoSession:
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            errorMessage:
                'Account created but there is no session yet. In Supabase: '
                'Authentication → Providers → Email → disable "Confirm email" '
                'so signup can upload your signature and save your profile in one step. '
                'Then try again (or use a new email if this one is already registered).',
          ),
        );
      case RegistrationResultKind.failure:
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            errorMessage: result.message ?? 'Registration failed.',
          ),
        );
    }
  }
}
