import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';

class AccountEditableFieldTile extends StatelessWidget {
  const AccountEditableFieldTile({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.icon,
    required this.valueText,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final String fieldKey;
  final IconData icon;
  final String valueText;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasValue = valueText.isNotEmpty;

    return Column(
      key: ValueKey<String>(fieldKey),
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasValue ? valueText : 'Tap to add',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: hasValue
                              ? scheme.onSurface
                              : scheme.outline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}
