import 'package:flutter/material.dart';

class AccountMutationOverlay extends StatelessWidget {
  const AccountMutationOverlay({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: Card(
          elevation: 0,
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Saving…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
