import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/router/app_shell_navigation.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/core/widgets/m3/app_status_chip.dart';
import 'package:inventopos/core/widgets/m3/app_sync_status_chip.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_needs_attention.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_payment_health.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_pulse_strip.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_top_sellers.dart';
import 'package:inventopos/presentation/dashboard/widgets/dashboard_ai_bootstrap.dart';
import 'package:inventopos/presentation/dashboard/widgets/quick_actions_grid.dart';
import 'package:inventopos/presentation/day_operations/widgets/dashboard_opening_snapshot.dart';
import 'package:inventopos/presentation/insights/widgets/dashboard_ai_briefing_card.dart';
import 'package:inventopos/presentation/inventory_automation/widgets/dashboard_reorder_alerts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: DashboardAiBootstrap(
          child: RefreshIndicator(
            onRefresh: () async {
              final uid =
                  context.read<AuthRepository>().currentSession?.userId;
              if (uid != null) {
                context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
              }
            },
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _DashboardHeader()),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _KpiSection(),
                      const SizedBox(height: AppSpacing.md),
                      const _PulseSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const _AttentionSection(),
                      const _QuickActionsSection(),
                      const SizedBox(height: AppSpacing.lg),
                      const DashboardAiBriefingCard(),
                      const SizedBox(height: AppSpacing.lg),
                      const DashboardOpeningSnapshot(),
                      const SizedBox(height: AppSpacing.lg),
                      const DashboardReorderAlerts(),
                      const SizedBox(height: AppSpacing.lg),
                      const _PaymentHealthSection(),
                      const _TopSellersSection(),
                      const _LowStockSection(),
                      const _RecentBillsSection(),
                      const SizedBox(height: AppSpacing.lg),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) =>
          p.profiles != c.profiles || p.notificationCount != c.notificationCount,
      builder: (context, state) {
        final theme = Theme.of(context);
        final hour = DateTime.now().hour;
        final business = state.profiles?.isNotEmpty == true
            ? state.profiles!.first.businessName ?? 'Your business'
            : 'Your business';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingForHour(hour),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      business,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, conn) {
                  return AppSyncStatusChip(
                    isOnline: conn.isOnline,
                    pendingCount: conn.pendingSyncCount,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_2_outlined),
                tooltip: 'Profile',
                onPressed: () => context.push('/app/profile'),
              ),
              IconButton(
                icon: Badge(
                  label: state.notificationCount > 0
                      ? Text('${state.notificationCount}')
                      : null,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.push('/app/notifications'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) =>
          p.revenueToday != c.revenueToday ||
          p.revenueThisMonth != c.revenueThisMonth ||
          p.partialBillsCount != c.partialBillsCount ||
          p.netProfitThisMonth != c.netProfitThisMonth,
      builder: (context, state) {
        return _KpiGrid(state: state);
      },
    );
  }
}

class _PulseSection extends StatelessWidget {
  const _PulseSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.bills != c.bills,
      builder: (context, state) => DashboardPulseStrip(state: state),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.attentionItemCount != c.attentionItemCount,
      builder: (context, state) {
        if (state.attentionItemCount == 0) return const SizedBox.shrink();
        return Column(
          children: [
            DashboardNeedsAttention(state: state),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) =>
          p.partialBillsCount != c.partialBillsCount ||
          p.lowStockCount != c.lowStockCount,
      builder: (context, state) => QuickActionsGrid(state: state),
    );
  }
}

class _PaymentHealthSection extends StatelessWidget {
  const _PaymentHealthSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.monthPaymentMix != c.monthPaymentMix,
      builder: (context, state) {
        if (state.monthPaymentMix.total == 0) return const SizedBox.shrink();
        return Column(
          children: [
            DashboardPaymentHealth(state: state),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _TopSellersSection extends StatelessWidget {
  const _TopSellersSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.topProductsThisMonth != c.topProductsThisMonth,
      builder: (context, state) {
        if (state.topProductsThisMonth.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            DashboardTopSellers(state: state),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.lowStockProducts != c.lowStockProducts,
      builder: (context, state) {
        if (state.lowStockProducts.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _LowStockAlerts(state: state),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _RecentBillsSection extends StatelessWidget {
  const _RecentBillsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHubBloc, DashboardHubState>(
      buildWhen: (p, c) => p.bills != c.bills,
      builder: (context, state) => _RecentBills(state: state),
    );
  }
}

String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final business = state.profiles?.isNotEmpty == true
        ? state.profiles!.first.businessName ?? 'Your business'
        : 'Your business';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingForHour(hour),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  business,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, conn) {
              return AppSyncStatusChip(
                isOnline: conn.isOnline,
                pendingCount: conn.pendingSyncCount,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_2_outlined),
            tooltip: 'Profile',
            onPressed: () => context.push('/app/profile'),
          ),
          IconButton(
            icon: Badge(
              label: state.notificationCount > 0
                  ? Text('${state.notificationCount}')
                  : null,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/app/notifications'),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final cross = AppBreakpoints.gridCrossAxisCount(context);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final trend = state.revenueTodayVsYesterdayPercent;
    final trendSubtitle = trend == null
        ? null
        : '${trend >= 0 ? '↑' : '↓'} ${trend.abs().toStringAsFixed(0)}% vs yesterday';
    final margin = state.profitMarginPercent;

    final revenueTodayCard = AppMetricCard(
      key: const ValueKey('kpi_revenue_today'),
      title: 'Revenue today',
      value: fmt.format(state.revenueToday),
      icon: Icons.today,
      color: Colors.green,
      subtitle: trendSubtitle,
      onTap: () => pushAppRootRoute(context, '/complete-transactions'),
    );
    final monthCard = AppMetricCard(
      key: const ValueKey('kpi_revenue_month'),
      title: 'This month',
      value: fmt.format(state.revenueThisMonth),
      icon: Icons.calendar_month,
      color: Colors.blue,
      subtitle: '${state.billsThisMonth} bills · ${state.billsToday} today',
      onTap: () => goAppAnalytics(context, tab: AnalyticsSuiteTab.revenue),
    );
    final pendingCard = AppMetricCard(
      key: const ValueKey('kpi_pending_dues'),
      title: 'Pending dues',
      value: state.partialBillsCount > 0
          ? fmt.format(state.pendingCollectionAmount)
          : 'None',
      icon: Icons.pending_actions,
      color: Colors.orange,
      subtitle: state.partialBillsCount > 0
          ? '${state.partialBillsCount} partial bills'
          : 'All caught up',
      onTap: () => pushAppRootRoute(context, '/incomplete-transactions'),
    );
    final profitCard = AppMetricCard(
      key: const ValueKey('kpi_net_profit'),
      title: 'Net profit (month)',
      value: fmt.format(state.netProfitThisMonth),
      icon: Icons.trending_up,
      color: Colors.purple,
      subtitle: margin != null
          ? '${margin.toStringAsFixed(0)}% margin · Exp ${fmt.format(state.monthExpenses)}'
          : 'Expenses ${fmt.format(state.monthExpenses)}',
      onTap: () => goAppAnalytics(context, tab: AnalyticsSuiteTab.pnl),
    );

    if (cross == 2) {
      const kpiHeight = AppMetricCard.heightWithSubtitle;
      return Column(
        children: [
          SizedBox(
            height: kpiHeight,
            child: Row(
              children: [
                Expanded(child: revenueTodayCard),
                const SizedBox(width: 12),
                Expanded(child: monthCard),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: kpiHeight,
            child: Row(
              children: [
                Expanded(child: pendingCard),
                const SizedBox(width: 12),
                Expanded(child: profitCard),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: cross,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12,
      children: [
        revenueTodayCard,
        monthCard,
        pendingCard,
        profitCard,
      ],
    );
  }
}

class _LowStockAlerts extends StatelessWidget {
  const _LowStockAlerts({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Low stock alerts',
      actionLabel: 'Inventory',
      onAction: () => context.go('/app/inventory'),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: state.lowStockProducts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final p = state.lowStockProducts[i];
            final out = p.stockQuantity <= 0;
            return ActionChip(
              avatar: Icon(
                out ? Icons.remove_shopping_cart : Icons.warning_amber,
                size: 18,
                color: out ? Colors.red : Colors.orange,
              ),
              label: Text('${p.name} (${p.stockQuantity})'),
              onPressed: () => context.go('/app/inventory'),
            );
          },
        ),
      ),
    );
  }
}

class _RecentBills extends StatelessWidget {
  const _RecentBills({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final bills = state.bills;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (bills == null || bills.isEmpty) {
      return AppSectionCard(
        title: 'Recent bills',
        actionLabel: 'New bill',
        onAction: () => context.go('/app/new-bill'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No bills yet. Create your first sale to see activity here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/app/new-bill'),
              icon: const Icon(Icons.add),
              label: const Text('Create bill'),
            ),
          ],
        ),
      );
    }

    final sorted = List<Bill>.from(bills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(6).toList();

    return AppSectionCard(
      title: 'Recent bills',
      actionLabel: 'View all',
      onAction: () => context.push('/complete-transactions'),
      child: Column(
        children: recent.map((b) => _BillRow(bill: b, fmt: fmt)).toList(),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, required this.fmt});

  final Bill bill;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = bill.paymentStatus.toLowerCase().trim();
    final statusColor = status == 'complete'
        ? Colors.green.shade700
        : status == 'partial'
            ? Colors.orange.shade800
            : theme.colorScheme.error;
    final amount = BillRevenue.recognizedAmount(bill);
    final label = bill.displayBillNumber?.trim().isNotEmpty == true
        ? '#${bill.displayBillNumber}'
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.receipt_long,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            bill.customerName.trim().isEmpty ? 'Walk-in' : bill.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (label != null) label,
              DateFormat('d MMM, h:mm a')
                  .format(BillRevenue.localCreatedDate(bill)),
            ].join(' · '),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              AppStatusChip(label: bill.paymentStatus, color: statusColor),
            ],
          ),
          onTap: () => context.push('/complete-transactions'),
        ),
      ),
    );
  }
}
