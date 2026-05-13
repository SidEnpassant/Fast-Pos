import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth/cubit/auth_flow_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCubit extends Cubit<AuthFlowState> {
  AuthCubit(this._authRepository)
      : super(const AuthFlowState(status: AuthFlowStatus.unknown)) {
    _sessionSubscription = _authRepository.sessionStream.listen(_onSession);
    _onSession(_authRepository.currentSession);
  }

  final AuthRepository _authRepository;
  StreamSubscription<Session?>? _sessionSubscription;

  void _onSession(Session? session) {
    if (session != null) {
      emit(state.copyWith(
        status: AuthFlowStatus.authenticated,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthFlowStatus.unauthenticated,
        isSubmitting: false,
      ));
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      emit(state.copyWith(isSubmitting: false));
    } on AuthException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: _mapLoginError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  String _mapLoginError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Wrong email or password';
    }
    return e.message.isNotEmpty ? e.message : 'Wrong email or password';
  }

  Future<void> signOut() => _authRepository.signOut();

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
