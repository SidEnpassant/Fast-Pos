import 'package:equatable/equatable.dart';

enum AiFailureCode {
  consentDenied,
  offline,
  rateLimited,
  budgetExceeded,
  parseError,
  serverError,
  unknown,
}

class AiFailure extends Equatable {
  const AiFailure({
    required this.code,
    this.message,
  });

  final AiFailureCode code;
  final String? message;

  @override
  List<Object?> get props => [code, message];
}

sealed class AiResult<T> {
  const AiResult();
}

final class AiSuccess<T> extends AiResult<T> {
  const AiSuccess(this.value);
  final T value;
}

final class AiError<T> extends AiResult<T> {
  const AiError(this.failure);
  final AiFailure failure;
}
