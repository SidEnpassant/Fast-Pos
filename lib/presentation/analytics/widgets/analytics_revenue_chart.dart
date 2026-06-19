import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_message_center.dart';

class AnalyticsRevenueChart extends StatelessWidget {
  const AnalyticsRevenueChart({
    super.key,
    required this.revenues,
    this.reference,
  });

  final Map<String, double> revenues;
  final DateTime? reference;

  @override
  Widget build(BuildContext context) {
    try {
      final ref = (reference ?? DateTime.now()).toLocal();
      final recentMonths = BusinessAnalytics.trailingMonthKeys(ref, count: 6);
      final revenueData = recentMonths.map((m) => revenues[m] ?? 0).toList();
      final hasAny = revenueData.any((v) => v > 0);
      if (!hasAny) {
        return const AnalyticsMessageCenter(
          message: 'No revenue in the last 6 months',
        );
      }

      final maxRevenue =
          revenueData.reduce((max, value) => value > max ? value : max);
      final yMax = maxRevenue <= 0 ? 1.0 : maxRevenue * 1.15;
      final yInterval = yMax > 0 ? (yMax / 4).clamp(1.0, double.infinity) : 1.0;
      final useBarChart = revenueData.where((v) => v > 0).length <= 2;

      return Container(
        height: 280,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: useBarChart
            ? _BarChart(
                months: recentMonths,
                data: revenueData,
                yMax: yMax,
                primary: Theme.of(context).colorScheme.primary,
              )
            : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: yMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${NumberFormat.compact().format(value)}',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < recentMonths.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                recentMonths[i].substring(0, 3),
                                style: GoogleFonts.poppins(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        revenueData.length,
                        (i) => FlSpot(i.toDouble(), revenueData[i]),
                      ),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.surface,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
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

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.months,
    required this.data,
    required this.yMax,
    required this.primary,
  });

  final List<String> months;
  final List<double> data;
  final double yMax;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: yMax,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < months.length) {
                  return Text(
                    months[i].substring(0, 3),
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: data[i] > 0 ? primary : primary.withValues(alpha: 0.2),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
