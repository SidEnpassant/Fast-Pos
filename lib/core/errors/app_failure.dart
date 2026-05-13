import 'package:equatable/equatable.dart';

/// Typed failures for consistent error handling across layers.
sealed class AppFailure extends Equatable {
  final String message;
  const AppFailure(this.message);

  @override
  List<Object?> get props => [message];
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class DataFailure extends AppFailure {
  const DataFailure(super.message);
}
