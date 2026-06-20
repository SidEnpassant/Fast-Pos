import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';

/// Date group label for transaction and history lists.
class AppDateSectionHeader extends StatelessWidget {
  const AppDateSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
