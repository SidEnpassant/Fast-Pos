import 'package:bloc/bloc.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._requestPasswordReset)
      : super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordUiCleared>(_onUiCleared);
  }

  final RequestPasswordResetUseCase _requestPasswordReset;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
        state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _requestPasswordReset(event.email.trim());
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } on AuthException catch (e) {
      final msg = e.message;
      if (msg.contains('User not found') ||
          msg.toLowerCase().contains('not found')) {
        emit(
          state.copyWith(
            status: ForgotPasswordStatus.failure,
            errorMessage: 'No user found for that email.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ForgotPasswordStatus.failure,
            errorMessage: msg.isEmpty ? 'Could not send reset email.' : msg,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onUiCleared(
    ForgotPasswordUiCleared event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordState());
  }
}
