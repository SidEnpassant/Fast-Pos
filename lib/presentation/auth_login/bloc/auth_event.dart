import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/auth_session.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged(this.session);

  final AuthSession? session;

  @override
  List<Object?> get props => [session];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
