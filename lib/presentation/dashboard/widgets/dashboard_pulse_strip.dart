import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

/// Horizontal today-at-a-glance metrics below KPIs.
class DashboardPulseStrip extends StatelessWidget {
  const DashboardPulseStrip({super.key, required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final trend = state.revenueTodayVsYesterdayPercent;
    final trendLabel = trend == null
        ? '—'
        : '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}% vs yesterday';

    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _PulseChip(
            icon: Icons.receipt_long,
            label: 'Bills today',
            value: '${state.billsToday}',
            color: Colors.indigo,
          ),
          _PulseChip(
            icon: Icons.payments,
            label: 'Avg bill',
            value: fmt.format(state.avgBillValueToday),
            color: Colors.teal,
          ),
          _PulseChip(
            icon: Icons.trending_up,
            label: 'Today trend',
            value: trendLabel,
            color: trend != null && trend >= 0 ? Colors.green : Colors.orange,
          ),
          _PulseChip(
            icon: Icons.people,
            label: 'Customers (month)',
            value: '${state.activeCustomersThisMonth}',
            color: Colors.deepPurple,
          ),
          if (state.partialBillsCount > 0)
            _PulseChip(
              icon: Icons.pending_actions,
              label: 'Pending dues',
              value: fmt.format(state.pendingCollectionAmount),
              color: Colors.orange,
            ),
        ],
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  const _PulseChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Container(
        width: 132,
        margin: EdgeInsets.only(right: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
