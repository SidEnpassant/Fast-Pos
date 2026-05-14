import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/auth/sign_out_use_case.dart';
import 'package:inventopos/domain/entities/auth_session.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_event.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_flow_state.dart';

/// Global auth/session [Bloc]. Sign-in runs through [LoginBloc] + [SignInUseCase].
class AuthBloc extends Bloc<AuthEvent, AuthFlowState> {
  AuthBloc(
    this._authRepository,
    this._signOutUseCase,
  ) : super(const AuthFlowState(status: AuthFlowStatus.unknown)) {
    on<AuthSessionChanged>(_onSessionChanged);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _sessionSubscription = _authRepository.sessionStream.listen(
      (session) => add(AuthSessionChanged(session)),
      onError: (_, __) => add(const AuthSessionChanged(null)),
    );
    add(AuthSessionChanged(_authRepository.currentSession));
  }

  final AuthRepository _authRepository;
  final SignOutUseCase _signOutUseCase;
  StreamSubscription<AuthSession?>? _sessionSubscription;

  void signOut() => add(const AuthSignOutRequested());

  void _onSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthFlowState> emit,
  ) {
    final session = event.session;
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthFlowStatus.authenticated,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthFlowStatus.unauthenticated,
          isSubmitting: false,
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

  @override
  Future<void> close() {
    _sessionSubscription?.cancel();
    return super.close();
  }
}
