/// Outcome of a full registration attempt (auth + profile + signature).
enum RegistrationResultKind {
  success,
  rejectedInvalid,
  rejectedNoSession,
  failure,
}

class RegistrationResult {
  const RegistrationResult._({
    required this.kind,
    this.message,
  });

  factory RegistrationResult.success() =>
      const RegistrationResult._(kind: RegistrationResultKind.success);

  factory RegistrationResult.rejectedInvalid([String? message]) =>
      RegistrationResult._(
        kind: RegistrationResultKind.rejectedInvalid,
        message: message,
      );

  factory RegistrationResult.rejectedNoSession() => const RegistrationResult._(
        kind: RegistrationResultKind.rejectedNoSession,
      );

  factory RegistrationResult.failure(String message) => RegistrationResult._(
        kind: RegistrationResultKind.failure,
        message: message,
      );

  final RegistrationResultKind kind;
  final String? message;
}
