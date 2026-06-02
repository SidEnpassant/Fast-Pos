import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';

class LoginCredentialsFields extends StatelessWidget {
  const LoginCredentialsFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    this.onSubmit,
    this.emailError,
    this.passwordError,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSubmit;
  final String? emailError;
  final String? passwordError;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: emailError,
            prefixIcon: const Icon(Icons.email_outlined),
            border: border,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (emailError != null) return emailError;
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: passwordError,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscure,
            ),
            border: border,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit?.call(),
          validator: (v) {
            if (passwordError != null) return passwordError;
            if (v == null || v.isEmpty) return 'Enter your password';
            return null;
          },
        ),
      ],
    );
  }
}
