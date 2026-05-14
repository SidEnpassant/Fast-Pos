import 'package:equatable/equatable.dart';

/// Minimal authenticated session for app code outside the data layer.
class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    this.email,
  });

  final String userId;
  final String? email;

  @override
  List<Object?> get props => [userId, email];
}
