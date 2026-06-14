import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_chart.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_table.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_stats_card.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_trend_chip.dart';

class AnalyticsRevenueContent extends StatelessWidget {
  const AnalyticsRevenueContent({super.key, required this.state});

  final AnalyticsHubState state;

  @override
  Widget build(BuildContext context) {
    final sortedMonths = state.sortedMonths;
    final monthlyRevenues = state.monthlyRevenues;
    final monthlyTransactions = state.monthlyTransactions;
    final selectedMonth = state.selectedMonth;
    final monthDate = BusinessAnalytics.parseMonthKey(selectedMonth);
    final revenue = selectedMonth != null
        ? (monthlyRevenues[selectedMonth] ?? 0)
        : 0.0;
    final txCount = selectedMonth != null
        ? (monthlyTransactions[selectedMonth] ?? 0)
        : 0;
    final avgTicket = txCount > 0 ? revenue / txCount : 0.0;

    MonthTrend? monthTrend;
    if (monthDate != null) {
      final prev = DateTime(monthDate.year, monthDate.month - 1, 1);
      final prevKey = BusinessAnalytics.monthKey(prev);
      final prevRev = monthlyRevenues[prevKey] ?? 0;
      monthTrend = MonthTrend(current: revenue, previous: prevRev);
    }

    final monthBills = monthDate == null
        ? const <Bill>[]
        : state.bills
            .where((b) => BillRevenue.isSameCalendarMonth(b, monthDate))
            .toList();

    final paymentMethods = <String, int>{};
    for (final b in monthBills) {
      final m = b.paymentMethod.trim().isEmpty ? 'Other' : b.paymentMethod;
      paymentMethods.update(m, (v) => v + 1, ifAbsent: () => 1);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        isExpanded: true,
                        items: sortedMonths.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(
                              month,
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            context.read<AnalyticsHubBloc>().setSelectedMonth(
                                  newValue,
                                );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedMonth != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnalyticsTrendChip(
                      changePercent: monthTrend?.changePercent,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnalyticsStatsCard(
                            title: 'Revenue',
                            value:
                                '₹${NumberFormat('#,##,###.##').format(revenue)}',
                            icon: Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnalyticsStatsCard(
                            title: 'Transactions',
                            value: '$txCount',
                            icon: Icons.receipt_long,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnalyticsStatsCard(
                      title: 'Average bill value',
                      value:
                          '₹${NumberFormat('#,##,###.##').format(avgTicket)}',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.deepPurple,
                    ),
                  ),
                  if (paymentMethods.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppSectionCard(
                        title: 'Payment methods',
                        child: Column(
                          children: paymentMethods.entries.map((e) {
                            final pct = txCount > 0
                                ? (e.value / txCount * 100).round()
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(e.key)),
                                  Text('$pct% · ${e.value} bills'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last 6 months',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<AnalyticsHubBloc>().toggleChartTable(),
                        icon: Icon(
                          state.showChart
                              ? Icons.table_chart
                              : Icons.show_chart,
                        ),
                        label: Text(
                          state.showChart ? 'Table' : 'Chart',
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.showChart)
                  AnalyticsRevenueChart(revenues: monthlyRevenues)
                else
                  AnalyticsRevenueTable(
                    months: sortedMonths,
                    revenues: monthlyRevenues,
                    transactions: monthlyTransactions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
