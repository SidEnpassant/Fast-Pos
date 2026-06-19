import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/presentation/daybook/bloc/daybook_bloc.dart';

class DayBookScreen extends StatelessWidget {
  const DayBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<DayBookBloc>()..add(DayBookStarted()),
      child: const DayBookView(),
    );
  }
}

class DayBookView extends StatelessWidget {
  const DayBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Day Book',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final bloc = context.read<DayBookBloc>();
            final date = await showDatePicker(
              context: context,
              initialDate: bloc.state.selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              bloc.add(DayBookDateChanged(date));
            }
          },
        ),
      ],
      body: BlocBuilder<DayBookBloc, DayBookState>(
        builder: (context, state) {
          if (state.status == DayBookStatus.loading && state.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = state.summary;
          if (summary == null) {
            return const Center(child: Text('No entries for this date'));
          }

          return Column(
            children: [
              _SummaryHeader(
                totalIn: summary.totalIn,
                totalOut: summary.totalOut,
                netBalance: summary.netBalance,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: summary.entries.length,
                  itemBuilder: (context, index) {
                    final entry = summary.entries[index];
                    return _CashEntryTile(entry: entry);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        label: const Text('Add Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'in';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Cash Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'in', label: Text('Cash In')),
                  ButtonSegment(value: 'out', label: Text('Cash Out')),
                ],
                selected: {type},
                onSelectionChanged: (val) => setState(() => type = val.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  context.read<DayBookBloc>().add(
                        DayBookEntryAdded(
                          amount: amount,
                          type: type,
                          note: noteController.text,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalIn,
    required this.totalOut,
    required this.netBalance,
  });

  final double totalIn;
  final double totalOut;
  final double netBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Cash In',
            amount: totalIn,
            color: Colors.green,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Cash Out',
            amount: totalOut,
            color: Colors.red,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _SummaryCard(
            label: 'Net',
            amount: netBalance,
            color: theme.colorScheme.primary,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.theme,
  });

  final String label;
  final double amount;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  currencyFormat.format(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashEntryTile extends StatelessWidget {
  const _CashEntryTile({required this.entry});

  final CashEntry entry;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final timeFormat = DateFormat.jm();
    final isIn = entry.type == 'in';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        child: Icon(
          isIn ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIn ? Colors.green : Colors.red,
        ),
      ),
      title: Text(entry.note ?? (isIn ? 'Cash In' : 'Cash Out')),
      subtitle: Text('${timeFormat.format(entry.entryDate)} ${entry.referenceType != null ? '• ${entry.referenceType}' : ''}'),
      trailing: Text(
        '${isIn ? '+' : '-'}${currencyFormat.format(entry.amount)}',
        style: TextStyle(
          color: isIn ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
