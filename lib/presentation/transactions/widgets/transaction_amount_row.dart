import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionAmountRow extends StatelessWidget {
  const TransactionAmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.valueColor,
  });

  final String label;
  final double amount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            fmt.format(amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
