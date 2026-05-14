import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_state.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_chart.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_table.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_stats_card.dart';

class AnalyticsRevenueContent extends StatelessWidget {
  const AnalyticsRevenueContent({super.key, required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final sortedMonths = state.sortedMonths;
    final monthlyRevenues = state.monthlyRevenues;
    final monthlyTransactions = state.monthlyTransactions;
    final selectedMonth = state.selectedMonth;

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
                            context.read<AnalyticsBloc>().setSelectedMonth(
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnalyticsStatsCard(
                            title: 'Revenue',
                            value:
                                '₹${NumberFormat('#,##,###.##').format(monthlyRevenues[selectedMonth] ?? 0)}',
                            icon: Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnalyticsStatsCard(
                            title: 'Transactions',
                            value:
                                '${monthlyTransactions[selectedMonth] ?? 0}',
                            icon: Icons.receipt_long,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.showChart)
                  AnalyticsRevenueChart(
                    months: sortedMonths,
                    revenues: monthlyRevenues,
                  )
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
