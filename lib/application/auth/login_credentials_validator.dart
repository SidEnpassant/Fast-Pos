/// Pure validation for login form (no Flutter imports).
class LoginCredentialsValidator {
  const LoginCredentialsValidator._();

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      return 'Please enter your email';
    }
    if (!v.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}
