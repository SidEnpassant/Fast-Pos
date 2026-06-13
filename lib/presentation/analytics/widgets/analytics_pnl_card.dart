import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';

/// Net profit = revenue − expenses for selected month (feature 6/13).
class AnalyticsPnLCard extends StatelessWidget {
  const AnalyticsPnLCard({super.key, required this.state});

  final AnalyticsHubState state;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthRepository>().currentSession?.userId ?? '';
    final month = state.selectedMonth;
    final revenue = month != null ? (state.monthlyRevenues[month] ?? 0) : 0.0;

    return StreamBuilder<List<Expense>>(
      stream: context.read<ExpenseRepository>().watchExpensesForUser(uid),
      builder: (context, snap) {
        final expenses = snap.data ?? [];
        final monthExpenses = month == null
            ? 0.0
            : expenses
                .where((e) {
                  final m =
                      '${_monthShort(e.expenseDate.month)} ${e.expenseDate.year}';
                  return m == month;
                })
                .fold<double>(0, (s, e) => s + e.amount);
        final net = revenue - monthExpenses;
        final margin = revenue > 0 ? (net / revenue) * 100 : 0.0;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profit & Loss',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Revenue: ₹${revenue.toStringAsFixed(2)}'),
                Text('Expenses: ₹${monthExpenses.toStringAsFixed(2)}'),
                Text(
                  'Net profit: ₹${net.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Margin: ${margin.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthShort(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}
