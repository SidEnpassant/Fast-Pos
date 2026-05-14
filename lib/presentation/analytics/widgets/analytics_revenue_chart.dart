import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_message_center.dart';

class AnalyticsRevenueChart extends StatelessWidget {
  const AnalyticsRevenueChart({
    super.key,
    required this.months,
    required this.revenues,
  });

  final List<String> months;
  final Map<String, double> revenues;

  @override
  Widget build(BuildContext context) {
    try {
      final recentMonths = months.take(6).toList().reversed.toList();
      final revenueData = recentMonths.map((m) => revenues[m] ?? 0).toList();
      if (revenueData.isEmpty) {
        return const AnalyticsMessageCenter(
          message: 'Error displaying chart',
        );
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
    } catch (_) {
      return const AnalyticsMessageCenter(
        message: 'Error displaying chart',
      );
    }
  }
}
