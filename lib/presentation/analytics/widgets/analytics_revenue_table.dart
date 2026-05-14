import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsRevenueTable extends StatelessWidget {
  const AnalyticsRevenueTable({
    super.key,
    required this.months,
    required this.revenues,
    required this.transactions,
  });

  final List<String> months;
  final Map<String, double> revenues;
  final Map<String, int> transactions;

  @override
  Widget build(BuildContext context) {
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
