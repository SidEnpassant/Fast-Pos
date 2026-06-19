import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/presentation/stock_audit/bloc/stock_audit_bloc.dart';

class StockAuditScreen extends StatefulWidget {
  const StockAuditScreen({super.key});

  @override
  State<StockAuditScreen> createState() => _StockAuditScreenState();
}

class _StockAuditScreenState extends State<StockAuditScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StockAuditBloc, StockAuditState>(
      listener: (context, state) {
        if (state.activeAudit == null && state.status == StockAuditViewState.success) {
          context.pop();
        }
      },
      builder: (context, state) {
        final audit = state.activeAudit;
        if (audit == null) {
          return const AppScreenScaffold(
            title: 'Live Audit',
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final itemsWithVariance = audit.lines.where((l) => l.variance != 0).length;

        return AppScreenScaffold(
          title: 'Live Audit',
          actions: [
            TextButton(
              onPressed: () => _showCancelDialog(context, audit.id),
              child: const Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Complete Audit',
              onPressed: () => _showCompleteDialog(context, audit.id),
            ),
          ],
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: AppMetricCard.heightCompact,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppMetricCard(
                          title: 'Total Items',
                          value: audit.lines.length.toString(),
                          icon: Icons.inventory_2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppMetricCard(
                          title: 'Variances',
                          value: itemsWithVariance.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: itemsWithVariance > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search product...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.search),
                  ),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, query, child) {
                    final filteredLines = audit.lines
                        .where((l) => l.productName.toLowerCase().contains(query))
                        .toList();

                    return ListView.builder(
                      itemCount: filteredLines.length,
                      itemBuilder: (context, index) {
                        final line = filteredLines[index];
                        return RepaintBoundary(
                          child: _AuditLineCard(line: line),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, String auditId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Audit?'),
        content: const Text('All counting progress will be lost and variance updates will be discarded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No, Continue')),
          TextButton(
            onPressed: () {
              context.read<StockAuditBloc>().add(CancelAudit(auditId));
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String auditId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Complete Audit?'),
        content: const Text('This will permanently update your inventory stock levels based on the physical counts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Review Again')),
          FilledButton(
            onPressed: () {
              context.read<StockAuditBloc>().add(CompleteAudit(auditId));
              Navigator.pop(context);
            },
            child: const Text('Complete Audit'),
          ),
        ],
      ),
    );
  }
}

class _AuditLineCard extends StatelessWidget {
  const _AuditLineCard({required this.line});

  final StockAuditLine line;

  void _updateQuantity(BuildContext context, double newQty) {
    if (newQty < 0) return;
    context.read<StockAuditBloc>().add(UpdateAuditLineQuantity(
          auditId: line.auditId,
          productId: line.productId,
          physicalQty: newQty,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOk = line.variance == 0;
    
    Color cardColor = scheme.surfaceContainerLowest;
    Color borderColor = scheme.outlineVariant.withOpacity(0.5);
    
    if (line.variance > 0) {
      cardColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green.withOpacity(0.3);
    } else if (line.variance < 0) {
      cardColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.3);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.productName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'System: ${line.systemQty.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOk ? 'Match' : '${line.variance > 0 ? '+' : ''}${line.variance.toStringAsFixed(0)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isOk ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Inline Stepper
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _updateQuantity(context, line.physicalQty - 1),
                      ),
                      InkWell(
                        onTap: () => _showEditQuantityDialog(context, line),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(minWidth: 36),
                          alignment: Alignment.center,
                          child: Text(
                            line.physicalQty.toStringAsFixed(0),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _updateQuantity(context, line.physicalQty + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(BuildContext context, StockAuditLine line) {
    final controller = TextEditingController(text: line.physicalQty.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Count: ${line.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Physical Quantity',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(controller.text) ?? line.physicalQty;
              _updateQuantity(context, qty);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
