import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/presentation/analytics/cubit/analytics_cubit.dart';
import 'package:inventopos/presentation/analytics/cubit/analytics_state.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MonthlyRevenueAnalysis extends StatelessWidget {
  const MonthlyRevenueAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(context, state),
              Expanded(
                child: !state.ready
                    ? _buildShimmerLoading()
                    : !state.hasRevenueData
                        ? _buildErrorWidget(
                            'No transaction data available',
                          )
                        : _buildBody(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AnalyticsState state) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.analytics_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Revenue Analysis',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              state.showChart ? Icons.table_chart : Icons.show_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () =>
                context.read<AnalyticsCubit>().toggleChartTable(),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: IconThemeData(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalyticsState state) {
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
                            context.read<AnalyticsCubit>().setSelectedMonth(
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
                          child: _buildStatsCard(
                            'Revenue',
                            '₹${NumberFormat('#,##,###.##').format(monthlyRevenues[selectedMonth] ?? 0)}',
                            Icons.account_balance_wallet,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatsCard(
                            'Transactions',
                            '${monthlyTransactions[selectedMonth] ?? 0}',
                            Icons.receipt_long,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.showChart)
                  _buildRevenueChart(context, sortedMonths, monthlyRevenues)
                else
                  _buildRevenueTable(
                    sortedMonths,
                    monthlyRevenues,
                    monthlyTransactions,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(
    BuildContext context,
    List<String> months,
    Map<String, double> revenues,
  ) {
    try {
      final recentMonths = months.take(6).toList().reversed.toList();
      final revenueData = recentMonths.map((m) => revenues[m] ?? 0).toList();
      if (revenueData.isEmpty) {
        return _buildErrorWidget('Error displaying chart');
      }

      final maxRevenue =
          revenueData.reduce((max, value) => value > max ? value : max);
      final yInterval = maxRevenue > 0 ? (maxRevenue / 5).roundToDouble() : 1.0;

      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[400]!.withValues(alpha: 0.5),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${NumberFormat.compact().format(value)}',
                      style: GoogleFonts.poppins(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < recentMonths.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          recentMonths[value.toInt()].substring(0, 3),
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  revenueData.length,
                  (index) => FlSpot(index.toDouble(), revenueData[index]),
                ),
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorWidget('Error displaying chart');
    }
  }

  Widget _buildRevenueTable(
    List<String> months,
    Map<String, double> revenues,
    Map<String, int> transactions,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Revenue')),
            DataColumn(label: Text('Transactions')),
          ],
          rows: List.generate(months.length, (index) {
            final month = months[index];
            final revenue = revenues[month] ?? 0;
            final transactionCount = transactions[month] ?? 0;

            return DataRow(
              cells: [
                DataCell(Text(month)),
                DataCell(
                  Text('₹${NumberFormat('#,##,###.##').format(revenue)}'),
                ),
                DataCell(Text('$transactionCount')),
              ],
            );
          }),
        ),
      ),
    );
  }
}
