import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged(this.session);

  final Session? session;

  @override
  List<Object?> get props => [session];
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
