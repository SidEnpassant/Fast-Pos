import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_state.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_message_center.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_pnl_card.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_shimmer_placeholder.dart';
import 'package:intl/intl.dart';

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
        if (hub.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                AppMetricCard(
                  title: 'Revenue (month)',
                  value: fmt.format(hub.revenueThisMonth),
                  icon: Icons.payments,
                  color: Colors.green,
                ),
                AppMetricCard(
                  title: 'Net profit',
                  value: fmt.format(hub.netProfit),
                  icon: Icons.trending_up,
                  color: Colors.indigo,
                ),
                AppMetricCard(
                  title: 'Expenses',
                  value: fmt.format(hub.expensesThisMonth),
                  icon: Icons.money_off,
                  color: Colors.orange,
                ),
                AppMetricCard(
                  title: 'Low stock SKUs',
                  value: '${hub.lowStockProducts.length}',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Bills this month',
              child: Text('${hub.bills.length} total bills'),
            ),
          ],
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
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnalyticsPnLCard(state: state),
            const SizedBox(height: 16),
            const AppSectionCard(
              title: 'Expense breakdown',
              child: Text('Track expenses from the Expenses screen'),
            ),
          ],
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
        if (hub.lowStockProducts.isEmpty) {
          return const Center(child: Text('No low-stock items'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hub.lowStockProducts.length,
          itemBuilder: (context, i) {
            final p = hub.lowStockProducts[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('Stock ${p.stockQuantity} / min ${p.minStockThreshold}'),
              trailing: Text('₹${p.price.toStringAsFixed(0)}'),
            );
          },
        );
      },
    );
  }
}

class _CustomersTab extends StatelessWidget {
  const _CustomersTab();

  @override
  Widget build(BuildContext context) {
    return const AppSectionCard(
      title: 'Customer insights',
      child: Text(
        'Customer credit and collection trends appear on the Dashboard.',
      ),
    );
  }
}
