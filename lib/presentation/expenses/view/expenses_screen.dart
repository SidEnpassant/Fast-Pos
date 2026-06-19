import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_filter_chip_bar.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_bloc.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_event.dart';
import 'package:inventopos/presentation/expenses/bloc/expenses_state.dart';
import 'package:inventopos/presentation/expenses/view/expense_editor_page.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<ExpensesBloc>().add(ExpensesStarted(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Expenses',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ExpenseEditorPage(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocBuilder<ExpensesBloc, ExpensesState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonList(itemCount: 8);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, conn) {
                  if (conn.isOnline) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 18,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline — changes sync when online',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppMetricCard.heightCompact,
                        child: AppMetricCard(
                          title: 'Period total',
                          value: '₹${state.periodTotal.toStringAsFixed(0)}',
                          icon: Icons.payments,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: AppMetricCard.heightCompact,
                        child: AppMetricCard(
                          title: 'Count',
                          value: '${state.periodCount}',
                          icon: Icons.receipt_long,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppFilterChipBar(
                labels: const ['Week', 'Month', 'Year', 'All'],
                selectedIndex: state.period.index,
                onSelected: (i) => context.read<ExpensesBloc>().add(
                      ExpensesPeriodChanged(ExpensePeriodFilter.values[i]),
                    ),
              ),
              if (state.categories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All categories'),
                        selected: state.categoryFilter == null,
                        onSelected: (_) => context
                            .read<ExpensesBloc>()
                            .add(const ExpensesCategoryChanged(null)),
                      ),
                      ...state.categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(c),
                            selected: state.categoryFilter == c,
                            onSelected: (_) => context
                                .read<ExpensesBloc>()
                                .add(ExpensesCategoryChanged(c)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: state.filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.receipt_long,
                        title: 'No expenses',
                        message: 'Tap Add to log your first expense',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filtered.length,
                        itemBuilder: (context, i) {
                          final e = state.filtered[i];
                          return Dismissible(
                            key: ValueKey(e.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => context
                                .read<ExpensesBloc>()
                                .add(ExpenseDeleted(e.id)),
                            background: Container(
                              color: Theme.of(context).colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(e.category),
                                subtitle: Text(
                                  DateFormat.yMMMd().format(e.expenseDate),
                                ),
                                trailing: Text(
                                  '₹${e.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ExpenseEditorPage(expense: e),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
