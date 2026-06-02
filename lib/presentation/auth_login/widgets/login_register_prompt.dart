import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginRegisterPrompt extends StatelessWidget {
  const LoginRegisterPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.push('/signup'),
          child: const Text('Create account'),
        ),
      ],
    );
  }
}
