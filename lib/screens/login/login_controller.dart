import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventopos/screens/register/signUpScreen.dart';

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
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (credential.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
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
