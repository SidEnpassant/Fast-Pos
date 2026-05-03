import 'package:flutter/material.dart';
import 'package:inventopos/screens/register/signUpScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void handleLogin(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    isLoadingNotifier.value = true;
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      String errorMessage = 'Wrong email or password';
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        errorMessage = 'Wrong email or password';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  VoidCallback goToRegisterScreen(BuildContext context) {
    return () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    };
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    isLoadingNotifier.dispose();
    obscureTextNotifier.dispose();
  }
}
