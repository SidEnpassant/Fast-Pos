import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_status_chip.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:intl/intl.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = product;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final low = p.isLowStock;
    final out = p.stockQuantity <= 0;
    final statusColor = out
        ? theme.colorScheme.error
        : low
            ? Colors.orange.shade800
            : Colors.green.shade700;
    final statusLabel = out ? 'Out' : low ? 'Low' : 'OK';
    final fill = p.minStockThreshold > 0
        ? (p.stockQuantity / (p.minStockThreshold * 2)).clamp(0.0, 1.0)
        : 1.0;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fmt.format(p.price),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (p.category != null && p.category!.isNotEmpty)
                              Text(
                                p.category!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppStatusChip(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: fill,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stock ${p.stockQuantity} / ${p.minStockThreshold}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  if (p.barcode != null && p.barcode!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.barcode!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
