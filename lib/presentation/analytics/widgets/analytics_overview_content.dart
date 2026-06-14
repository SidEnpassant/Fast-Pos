import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_shimmer_placeholder.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_trend_chip.dart';

class AnalyticsOverviewContent extends StatelessWidget {
  const AnalyticsOverviewContent({
    super.key,
    required this.snapshot,
    required this.revenueThisMonth,
    required this.netProfit,
    required this.expensesThisMonth,
    required this.lowStockCount,
    required this.billsThisMonth,
    this.loading = false,
  });

  final BusinessAnalyticsSnapshot snapshot;
  final double revenueThisMonth;
  final double netProfit;
  final double expensesThisMonth;
  final int lowStockCount;
  final int billsThisMonth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AnalyticsShimmerPlaceholder();
    }

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat('d MMM, h:mm a');
    final insights = snapshot;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AnalyticsTrendChip(
            changePercent: insights.revenueTrend.changePercent,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            AppMetricCard(
              title: 'Revenue (month)',
              value: fmt.format(revenueThisMonth),
              subtitle: _trendSubtitle(insights.revenueTrend),
              icon: Icons.payments,
              color: Colors.green,
            ),
            AppMetricCard(
              title: 'Net profit',
              value: fmt.format(netProfit),
              subtitle: _trendSubtitle(insights.profitTrend),
              icon: Icons.trending_up,
              color: Colors.indigo,
            ),
            AppMetricCard(
              title: 'Expenses',
              value: fmt.format(expensesThisMonth),
              subtitle: _trendSubtitle(insights.expensesTrend, invert: true),
              icon: Icons.money_off,
              color: Colors.orange,
            ),
            AppMetricCard(
              title: 'Low stock SKUs',
              value: '$lowStockCount',
              subtitle: insights.inventory.outOfStock > 0
                  ? '${insights.inventory.outOfStock} out of stock'
                  : null,
              icon: Icons.warning_amber,
              color: Colors.red,
              onTap: lowStockCount > 0
                  ? () => context.go('/app/inventory')
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'Bills this month',
          actionLabel: 'View all',
          onAction: () => context.push('/complete-transactions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$billsThisMonth bills · Avg ${fmt.format(insights.avgBillValueThisMonth)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _PaymentMixBar(mix: insights.paymentMix),
              if (insights.recentBills.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'No bills yet this period. Create a bill from New Bill.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                ...insights.recentBills.map(
                  (b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.receipt,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      '${b.label} · ${b.customerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(dateFmt.format(b.createdAt)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt.format(b.amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          b.paymentStatus,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (insights.topProductsThisMonth.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Top sellers (this month)',
            child: Column(
              children: insights.topProductsThisMonth.take(5).map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${p.unitsSold} sold',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        fmt.format(p.revenue),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  String? _trendSubtitle(MonthTrend trend, {bool invert = false}) {
    final pct = trend.changePercent;
    if (pct == null) return null;
    final up = pct >= 0;
    final good = invert ? !up : up;
    final arrow = up ? '↑' : '↓';
    return '$arrow ${pct.abs().toStringAsFixed(0)}% vs last month${good ? '' : ''}';
  }
}

class _PaymentMixBar extends StatelessWidget {
  const _PaymentMixBar({required this.mix});

  final PaymentMixSnapshot mix;

  @override
  Widget build(BuildContext context) {
    final total = mix.total;
    if (total == 0) {
      return Text(
        'Payment status will appear after your first bill.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    Widget segment(double flex, Color color) {
      if (flex <= 0) return const SizedBox.shrink();
      return Expanded(
        flex: flex.round().clamp(1, 9999),
        child: Container(color: color),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                segment(mix.complete.toDouble(), Colors.green),
                segment(mix.partial.toDouble(), Colors.orange),
                segment(mix.pending.toDouble(), Colors.red.shade300),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _Legend('Paid', mix.complete, Colors.green),
            _Legend('Partial', mix.partial, Colors.orange),
            _Legend('Pending', mix.pending, Colors.red.shade300),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $count', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
