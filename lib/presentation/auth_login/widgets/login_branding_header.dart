import 'package:flutter/material.dart';

class LoginBrandingHeader extends StatelessWidget {
  const LoginBrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        const SizedBox(height: 50),
        Center(
          child: Text(
            'FastPOS',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
