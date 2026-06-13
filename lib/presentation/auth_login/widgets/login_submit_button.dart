import 'package:flutter/material.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const AppShimmer(
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
