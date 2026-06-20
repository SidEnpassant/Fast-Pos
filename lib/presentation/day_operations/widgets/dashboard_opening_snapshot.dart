import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_bloc.dart';
import 'package:inventopos/presentation/day_operations/bloc/day_operations_state.dart';

class DashboardOpeningSnapshot extends StatelessWidget {
  const DashboardOpeningSnapshot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DayOperationsBloc, DayOperationsState>(
      builder: (context, state) {
        if (state.loading) return const SizedBox.shrink();
        if (state.partialCount == 0 &&
            state.lowStockCount == 0 &&
            state.pending <= 0) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s attention',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '${state.partialCount} partial bills · '
                  '₹${state.pending.toStringAsFixed(0)} to collect · '
                  '${state.lowStockCount} low stock',
                ),
                if (state.billCount > 0) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Today: ${state.billCount} bills · '
                    '₹${state.revenue.toStringAsFixed(0)} sales',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (state.expenseSpike)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Expenses spiked vs recent weeks',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
