import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/analytics/customer_analytics.dart';
import 'package:intl/intl.dart';

class AnalyticsCustomersContent extends StatelessWidget {
  const AnalyticsCustomersContent({
    super.key,
    required this.snapshot,
    this.loading = false,
  });

  final CustomerAnalyticsSnapshot snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.totalCustomers == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No customer data yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create bills with customer name or phone to see insights here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/customers'),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Manage customers'),
              ),
            ],
          ),
        ),
      );
    }

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final repeatRate = snapshot.activeThisMonth > 0
        ? (snapshot.repeatCustomers / snapshot.activeThisMonth * 100)
            .round()
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            AppMetricCard(
              title: 'Total customers',
              value: '${snapshot.totalCustomers}',
              icon: Icons.people,
              color: Colors.indigo,
            ),
            AppMetricCard(
              title: 'Active this month',
              value: '${snapshot.activeThisMonth}',
              icon: Icons.how_to_reg,
              color: Colors.teal,
            ),
            AppMetricCard(
              title: 'Outstanding credit',
              value: fmt.format(snapshot.totalOutstandingCredit),
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
            ),
            AppMetricCard(
              title: 'Pending collections',
              value: fmt.format(snapshot.pendingFromPartialBills),
              icon: Icons.pending_actions,
              color: Colors.deepOrange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'This month',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(
                label: 'New customers',
                value: '${snapshot.newCustomersThisMonth}',
                icon: Icons.fiber_new,
              ),
              _StatRow(
                label: 'Repeat buyers',
                value:
                    '${snapshot.repeatCustomers} ($repeatRate% of active)',
                icon: Icons.repeat,
              ),
              _StatRow(
                label: 'Fully paid bills',
                value: '${snapshot.completeBillsThisMonth}',
                icon: Icons.check_circle_outline,
              ),
              _StatRow(
                label: 'Partial / pending bills',
                value: '${snapshot.partialBillsThisMonth}',
                icon: Icons.hourglass_empty,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (snapshot.topByRevenueThisMonth.isNotEmpty)
          AppSectionCard(
            title: 'Top customers by revenue',
            actionLabel: 'View all',
            onAction: () => context.push('/customers'),
            child: Column(
              children: [
                for (var i = 0; i < snapshot.topByRevenueThisMonth.length; i++)
                  _CustomerRankTile(
                    rank: i + 1,
                    entry: snapshot.topByRevenueThisMonth[i],
                    amountLabel: fmt.format(
                      snapshot.topByRevenueThisMonth[i].revenueThisMonth,
                    ),
                    subtitle:
                        '${snapshot.topByRevenueThisMonth[i].billsThisMonth} bill(s) this month',
                  ),
              ],
            ),
          ),
        if (snapshot.withPendingBills.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Pending bill collections',
            child: Column(
              children: [
                for (final e in snapshot.withPendingBills)
                  _CustomerRankTile(
                    entry: e,
                    amountLabel: fmt.format(e.pendingOnBills),
                    subtitle: 'Due on open partial bills',
                    amountColor: Colors.deepOrange,
                  ),
              ],
            ),
          ),
        ],
        if (snapshot.withOutstandingCredit.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppSectionCard(
            title: 'Customers with credit balance',
            child: Column(
              children: [
                for (final e in snapshot.withOutstandingCredit)
                  _CustomerRankTile(
                    entry: e,
                    amountLabel: fmt.format(e.outstandingCredit),
                    subtitle: e.phone?.isNotEmpty == true
                        ? e.phone!
                        : 'Store credit',
                    amountColor: Colors.orange,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push('/customers'),
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Open customer directory'),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRankTile extends StatelessWidget {
  const _CustomerRankTile({
    required this.entry,
    required this.amountLabel,
    required this.subtitle,
    this.rank,
    this.amountColor,
  });

  final CustomerRankEntry entry;
  final String amountLabel;
  final String subtitle;
  final int? rank;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: rank != null
            ? Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : Icon(
                Icons.person,
                color: theme.colorScheme.onPrimaryContainer,
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (entry.isNewThisMonth)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        amountLabel,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: amountColor ?? theme.colorScheme.primary,
        ),
      ),
      onTap: entry.customerId != null
          ? () => context.push('/customers/${entry.customerId}')
          : null,
    );
  }
}
