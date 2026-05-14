/// Thrown when sign-in, password reset, or similar auth operations fail.
class AuthOperationFailure implements Exception {
  AuthOperationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
