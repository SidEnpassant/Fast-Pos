import 'package:flutter/material.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';

/// Standard loading / error / empty / content slots for async pages.
class AppAsyncBody<T> extends StatelessWidget {
  const AppAsyncBody({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.loadingWidget,
  });

  final bool isLoading;
  final bool isEmpty;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(errorMessage!, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }
    if (isLoading) {
      return loadingWidget ?? const AppSkeletonList();
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'Nothing to show',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return child;
  }
}
