import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/router/app_shell_navigation.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_state.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_message_center.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_customers_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_inventory_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_overview_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_pnl_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_shimmer_placeholder.dart';
class AnalyticsSuiteScreen extends StatefulWidget {
  const AnalyticsSuiteScreen({super.key});

  @override
  State<AnalyticsSuiteScreen> createState() => _AnalyticsSuiteScreenState();
}

class _AnalyticsSuiteScreenState extends State<AnalyticsSuiteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    context.read<AnalyticsHubBloc>().add(const AnalyticsHubStarted());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyTabFromRoute();
  }

  void _applyTabFromRoute() {
    final index = analyticsTabIndexFromRoute(GoRouterState.of(context));
    if (index == null || index == _tabs.index) return;
    _tabs.animateTo(index);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics',
        style: TextStyle(
          fontSize: 20,
         ),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'P&L'),
            Tab(text: 'Inventory'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OverviewTab(),
          _RevenueTab(),
          _PnLTab(),
          _InventoryTab(),
          _CustomersTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsHubBloc, AnalyticsHubState>(
      builder: (context, hub) {
        return AnalyticsOverviewContent(
          snapshot: hub.businessInsights,
          revenueThisMonth: hub.revenueThisMonth,
          netProfit: hub.netProfit,
          expensesThisMonth: hub.expensesThisMonth,
          lowStockCount: hub.lowStockProducts.length,
          billsThisMonth: hub.billsThisMonth,
          loading: hub.loading,
        );
      },
    );
  }
}

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (!state.ready) return const AnalyticsShimmerPlaceholder();
        if (!state.hasRevenueData) {
          return const AnalyticsMessageCenter(
            message: 'No transaction data available',
          );
        }
        return AnalyticsRevenueContent(state: state);
      },
    );
  }
}

class _PnLTab extends StatelessWidget {
  const _PnLTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsHubBloc, AnalyticsHubState>(
      builder: (context, hub) {
        return BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (hub.loading || !state.ready) {
              return const Center(child: CircularProgressIndicator());
            }
            final monthKey = state.selectedMonth;
            final monthDate =
                BusinessAnalytics.parseMonthKey(monthKey) ?? DateTime.now();
            final revenue = monthKey != null
                ? (state.monthlyRevenues[monthKey] ?? 0)
                : hub.revenueThisMonth;
            final expenses = BusinessAnalytics.expensesForMonth(
              hub.expenses,
              monthDate,
            );
            final breakdown = BusinessAnalytics.expenseBreakdownForMonth(
              hub.expenses,
              monthDate,
            );
            return Column(
              children: [
                if (state.sortedMonths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<String>(
                      value: monthKey,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: state.sortedMonths
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (m) {
                        if (m != null) {
                          context.read<AnalyticsBloc>().setSelectedMonth(m);
                        }
                      },
                    ),
                  ),
                Expanded(
                  child: AnalyticsPnLContent(
                    revenue: revenue,
                    expenses: expenses,
                    breakdown: breakdown,
                    monthLabel: monthKey,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsHubBloc, AnalyticsHubState>(
      builder: (context, hub) {
        return AnalyticsInventoryContent(
          inventory: hub.businessInsights.inventory,
          loading: hub.loading,
        );
      },
    );
  }
}

class _CustomersTab extends StatelessWidget {
  const _CustomersTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsHubBloc, AnalyticsHubState>(
      builder: (context, hub) {
        return AnalyticsCustomersContent(
          snapshot: hub.customerInsights,
          loading: hub.loading,
        );
      },
    );
  }
}
