import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordFooterLinks extends StatelessWidget {
  const ForgotPasswordFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: const Text(
            'Create',
            style: TextStyle(
              color: Color.fromARGB(225, 184, 166, 6),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
