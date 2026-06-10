import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';

/// M3-aligned section card for bill form sections.
/// Matches [AppSectionCard] style from dashboard and other screens.
class BillSectionCard extends StatelessWidget {
  const BillSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Theme-aware input decoration that follows the app's M3 input theme.
InputDecoration billGenerationInputDecoration(
  String label,
  IconData icon, {
  BuildContext? context,
}) {
  // If a context is provided, use theme colors; otherwise fall back to
  // the app-level InputDecorationTheme which is already M3-aligned.
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    filled: true,
  );
}

class BillGenerationDropdownField extends StatelessWidget {
  const BillGenerationDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(value),
      initialValue: value,
      decoration: billGenerationInputDecoration(label, prefixIcon),
      items: items.entries
          .map(
            (e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
