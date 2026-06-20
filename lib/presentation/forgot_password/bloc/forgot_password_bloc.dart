import 'package:bloc/bloc.dart';
import 'package:inventopos/application/auth/request_password_reset_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/application/auth/update_password_use_case.dart';
import 'package:inventopos/application/auth/verify_recovery_otp_use_case.dart';
import 'package:inventopos/domain/auth/auth_operation_failure.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_event.dart';
import 'package:inventopos/presentation/forgot_password/bloc/forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(
    this._requestPasswordReset,
    this._verifyRecoveryOtp,
    this._updatePassword,
    this._signOut,
  ) : super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordOtpSubmitted>(_onOtpSubmitted);
    on<ForgotPasswordNewPasswordSubmitted>(_onNewPasswordSubmitted);
    on<ForgotPasswordBackRequested>(_onBackRequested);
    on<ForgotPasswordUiCleared>(_onUiCleared);
  }

  final RequestPasswordResetUseCase _requestPasswordReset;
  final VerifyRecoveryOtpUseCase _verifyRecoveryOtp;
  final UpdatePasswordUseCase _updatePassword;
  final SignOutUseCase _signOut;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        email: event.email.trim(),
        clearError: true,
      ),
    );
    try {
      await _requestPasswordReset(event.email.trim());
      emit(state.copyWith(
        status: ForgotPasswordStatus.initial,
        step: ForgotPasswordStep.otp,
      ));
    } on AuthOperationFailure catch (e) {
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

  Future<void> _onOtpSubmitted(
    ForgotPasswordOtpSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
        state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _verifyRecoveryOtp(
        email: state.email,
        otp: event.otp.trim(),
      );
      emit(state.copyWith(
        status: ForgotPasswordStatus.initial,
        step: ForgotPasswordStep.newPassword,
      ));
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: 'Invalid or expired OTP.',
        ),
      );
    }
  }

  Future<void> _onNewPasswordSubmitted(
    ForgotPasswordNewPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
        state.copyWith(status: ForgotPasswordStatus.loading, clearError: true));
    try {
      await _updatePassword(event.newPassword);
      await _signOut();
      emit(state.copyWith(
        status: ForgotPasswordStatus.success,
        step: ForgotPasswordStep.success,
      ));
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: 'Failed to update password.',
        ),
      );
    }
  }

  void _onBackRequested(
    ForgotPasswordBackRequested event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state.step == ForgotPasswordStep.otp) {
      emit(state.copyWith(
        step: ForgotPasswordStep.email,
        clearError: true,
      ));
    }
  }

  void _onUiCleared(
    ForgotPasswordUiCleared event,
    Emitter<ForgotPasswordState> emit,
  ) {
    // Just clear the error message if any
    emit(state.copyWith(clearError: true, status: ForgotPasswordStatus.initial));
  }
}
