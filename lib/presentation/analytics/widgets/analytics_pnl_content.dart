import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';

class AnalyticsPnLContent extends StatelessWidget {
  const AnalyticsPnLContent({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.breakdown,
    this.monthLabel,
  });

  final double revenue;
  final double expenses;
  final List<ExpenseCategoryRow> breakdown;
  final String? monthLabel;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final net = revenue - expenses;
    final margin = revenue > 0 ? (net / revenue) * 100 : 0.0;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel != null
                      ? 'Profit & Loss · $monthLabel'
                      : 'Profit & Loss',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _PnLLine('Revenue', fmt.format(revenue)),
                _PnLLine('Expenses', fmt.format(expenses)),
                const Divider(),
                _PnLLine(
                  'Net profit',
                  fmt.format(net),
                  bold: true,
                  valueColor: net >= 0 ? Colors.green.shade800 : Colors.red,
                ),
                _PnLLine('Margin', '${margin.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'Expense breakdown',
          actionLabel: 'Add expense',
          onAction: () => context.push('/expenses'),
          child: breakdown.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No expenses recorded for this month.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log rent, salaries, utilities, and supplies to see margin accurately.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: breakdown.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.category,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              Text(
                                fmt.format(row.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (row.sharePercent / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${row.sharePercent.toStringAsFixed(0)}% of expenses',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'Tips',
          child: Text(
            'Healthy retail margins are often 15–40% after operating expenses. '
            'Compare revenue trends on the Revenue tab and keep low-stock items restocked.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PnLLine extends StatelessWidget {
  const _PnLLine(
    this.label,
    this.value, {
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
