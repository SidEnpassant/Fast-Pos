import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/presentation/daybook/bloc/daybook_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventopos/domain/pdf/daybook_pdf_generator.dart';
import 'package:open_file/open_file.dart';

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
    final theme = Theme.of(context);
    return AppScreenScaffold(
      title: 'Day Book (Khata)',
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'Export PDF',
          onPressed: () async {
            final summary = context.read<DayBookBloc>().state.summary;
            if (summary == null || summary.entries.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No entries to generate PDF')),
              );
              return;
            }
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              final file = await DayBookPdfGenerator.generate(summary);
              if (context.mounted) Navigator.pop(context); // close loader
              await OpenFile.open(file.path);
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error generating PDF: $e')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Select Date Range',
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
            return AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No entries for this date',
              message: 'Start by adding a new cash in or out entry.',
              actionLabel: 'Add Entry',
              onAction: () => _showAddEntryDialog(context),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: _SummaryHeader(
                    totalIn: summary.totalIn,
                    totalOut: summary.totalOut,
                    netBalance: summary.netBalance,
                    entries: summary.entries,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('All'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Cash In'),
                        avatar: const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Cash Out'),
                        avatar: const Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                        onPressed: () {},
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),
                ),
              ),
              if (summary.entries.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No entries',
                    message: 'No cash entries recorded for this date yet.',
                  ).animate().fadeIn(duration: 400.ms),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = summary.entries[index];
                        return _CashEntryTile(entry: entry)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 50 * index.clamp(0, 10)))
                            .slideY(begin: 0.1, end: 0);
                      },
                      childCount: summary.entries.length,
                    ),
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
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
    required this.entries,
  });

  final double totalIn;
  final double totalOut;
  final double netBalance;
  final List<CashEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Balance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: netBalance >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        netBalance >= 0 ? 'Surplus' : 'Deficit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: netBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹',
                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,##,###.##').format(netBalance),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ).animate().shimmer(duration: 1500.ms),
                const SizedBox(height: 24),
                if (entries.isNotEmpty) ...[
                  SizedBox(
                    height: 60,
                    child: _MiniChart(entries: entries),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Cash In',
                        amount: totalIn,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                    Expanded(
                      child: _StatColumn(
                        label: 'Cash Out',
                        amount: totalOut,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
  }
}

class _MiniChart extends StatelessWidget {
  final List<CashEntry> entries;
  const _MiniChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox();

    // Extremely simplified data mapping for mini chart visualization
    List<FlSpot> spots = [];
    double running = 0;
    
    // Reverse entries to show chronological from left to right if they are sorted newest first
    final chronological = entries.reversed.toList();
    for (int i = 0; i < chronological.length; i++) {
      if (chronological[i].type == 'in') {
        running += chronological[i].amount;
      } else {
        running -= chronological[i].amount;
      }
      spots.add(FlSpot(i.toDouble(), running));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}


class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatColumn({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
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
    final theme = Theme.of(context);

    // Determine icon based on reference type
    IconData getIcon() {
      if (entry.referenceType == 'sale') return Icons.shopping_bag_outlined;
      if (entry.referenceType == 'expense') return Icons.receipt_long_outlined;
      if (entry.referenceType == 'supplier_payment') return Icons.local_shipping_outlined;
      return isIn ? Icons.attach_money : Icons.money_off;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                color: isIn ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note ?? (isIn ? 'Cash In' : 'Cash Out'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(entry.entryDate),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (entry.referenceType != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.referenceType!.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIn ? '+' : '-'}${currencyFormat.format(entry.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isIn ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
