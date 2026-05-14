import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountMutationOverlay extends StatelessWidget {
  const AccountMutationOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: const Color(0xFF3B82F6),
            size: 40,
          ),
        ),
      ),
    );
  }
}
