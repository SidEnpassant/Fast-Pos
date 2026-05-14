import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Form + validation only; auth is handled by [AuthBloc].
class LoginController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoadingNotifier = ValueNotifier<bool>(false);
  final obscureTextNotifier = ValueNotifier<bool>(true);

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  void togglePasswordVisibility() {
    obscureTextNotifier.value = !obscureTextNotifier.value;
  }

  VoidCallback goToRegisterScreen(BuildContext context) {
    return () => context.push('/signup');
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    isLoadingNotifier.dispose();
    obscureTextNotifier.dispose();
  }
}
