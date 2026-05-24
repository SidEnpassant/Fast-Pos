import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/responsive/app_breakpoints.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_quick_action_tile.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/core/widgets/m3/app_sync_status_chip.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_bloc.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_event.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/presentation/dashboard/widgets/quick_actions_grid.dart';

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
        child: BlocBuilder<DashboardHubBloc, DashboardHubState>(
          builder: (context, state) {
            if (state.loading && state.bills == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () async {
                final uid =
                    context.read<AuthRepository>().currentSession?.userId;
                if (uid != null) {
                  context.read<DashboardHubBloc>().add(DashboardHubStarted(uid));
                }
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Header(state: state)),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _KpiGrid(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        const QuickActionsGrid(),
                        if (state.lowStockProducts.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _LowStockAlerts(state: state),
                        ],
                        if (state.topCreditCustomers.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _CreditDueStrip(state: state),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _RecentBills(state: state),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business =
        state.profiles?.isNotEmpty == true
            ? state.profiles!.first.businessName ?? 'Your Business'
            : 'Your Business';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  business,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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

    return GridView.count(
      crossAxisCount: cross,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        AppMetricCard(
          title: 'Revenue today',
          value: fmt.format(state.revenueToday),
          icon: Icons.today,
          color: Colors.green,
        ),
        AppMetricCard(
          title: 'This month',
          value: fmt.format(state.revenueThisMonth),
          icon: Icons.calendar_month,
          color: Colors.blue,
          subtitle: '${state.billsToday} bills today',
        ),
        AppMetricCard(
          title: 'Low stock',
          value: '${state.lowStockCount}',
          icon: Icons.warning_amber,
          color: Colors.orange,
          onTap: () => context.go('/app/inventory'),
        ),
        AppMetricCard(
          title: 'Net profit (month)',
          value: fmt.format(state.netProfitThisMonth),
          icon: Icons.trending_up,
          color: Colors.purple,
          subtitle: 'Expenses ${fmt.format(state.monthExpenses)}',
        ),
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
      actionLabel: 'View all',
      onAction: () => context.go('/app/inventory'),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: state.lowStockProducts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final p = state.lowStockProducts[i];
            return ActionChip(
              avatar: const Icon(Icons.warning_amber, size: 18),
              label: Text('${p.name} (${p.stockQuantity})'),
              onPressed: () => context.go('/app/inventory'),
            );
          },
        ),
      ),
    );
  }
}

class _CreditDueStrip extends StatelessWidget {
  const _CreditDueStrip({required this.state});

  final DashboardHubState state;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return AppSectionCard(
      title: 'Credit due',
      actionLabel: 'Customers',
      onAction: () => context.push('/customers'),
      child: Column(
        children: state.topCreditCustomers.map((c) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
            title: Text(c.name),
            subtitle: Text(c.phone ?? ''),
            trailing: Text(
              fmt.format(c.creditBalance),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => context.push('/customers/${c.id}'),
          );
        }).toList(),
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
    if (bills == null || bills.isEmpty) {
      return AppSectionCard(
        title: 'Recent bills',
        child: Text(
          'No bills yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final sorted = List<Bill>.from(bills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(5).toList();

    return AppSectionCard(
      title: 'Recent bills',
      actionLabel: 'All',
      onAction: () => context.push('/complete-transactions'),
      child: Column(
        children: recent.map((b) => _BillRow(bill: b)).toList(),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor = theme.colorScheme.outline;
    final pl = bill.paymentStatus.toLowerCase();
    if (pl == 'complete' || pl == 'paid') statusColor = Colors.green;
    if (pl == 'partial') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(bill.customerName),
        subtitle: Text('₹${bill.totalAmount.toStringAsFixed(2)}'),
        trailing: Chip(
          label: Text(bill.paymentStatus),
          backgroundColor: statusColor.withValues(alpha: 0.12),
          labelStyle: TextStyle(color: statusColor, fontSize: 12),
        ),
      ),
    );
  }
}
