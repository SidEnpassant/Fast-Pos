import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/auth/sign_in_use_case.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthBloc extends Bloc<AuthEvent, AuthFlowState> {
  AuthBloc(
    this._authRepository,
    this._signInUseCase,
    this._signOutUseCase,
  ) : super(const AuthFlowState(status: AuthFlowStatus.unknown)) {
    on<AuthSessionChanged>(_onSessionChanged);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _sessionSubscription = _authRepository.sessionStream.listen(
      (session) => add(AuthSessionChanged(session)),
      onError: (_, __) => add(const AuthSessionChanged(null)),
    );
    add(AuthSessionChanged(_authRepository.currentSession));
  }

  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  StreamSubscription<Session?>? _sessionSubscription;

  void signInWithPassword({
    required String email,
    required String password,
  }) {
    add(AuthLoginSubmitted(email: email, password: password));
  }

  void signOut() => add(const AuthSignOutRequested());

  void _onSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthFlowState> emit,
  ) {
    final session = event.session;
    if (session != null) {
      emit(state.copyWith(status: AuthFlowStatus.authenticated, clearError: true));
    } else {
      emit(
        state.copyWith(
          status: AuthFlowStatus.unauthenticated,
          isSubmitting: false,
        ),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthFlowState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _signInUseCase(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(isSubmitting: false));
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _mapLoginError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthFlowState> emit,
  ) async {
    await _signOutUseCase();
  }

  String _mapLoginError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Wrong email or password';
    }
    return e.message.isNotEmpty ? e.message : 'Wrong email or password';
  }

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
