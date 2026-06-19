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
  String _searchQuery = '';

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

        final filteredLines = audit.lines
            .where((l) => l.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        final itemsWithVariance = audit.lines.where((l) => l.variance != 0).length;

        return AppScreenScaffold(
          title: 'Live Audit',
          actions: [
            TextButton(
              onPressed: () => _showCancelDialog(context, audit.id),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            IconButton(
              icon: const Icon(Icons.check),
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
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search product...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredLines.length,
                  itemBuilder: (context, index) {
                    final line = filteredLines[index];
                    return ListTile(
                      title: Text(line.productName),
                      subtitle: Text('System: ${line.systemQty} | Physical: ${line.physicalQty}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            line.variance == 0 ? 'OK' : line.variance.toStringAsFixed(2),
                            style: TextStyle(
                              color: line.variance == 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditQuantityDialog(context, line),
                          ),
                        ],
                      ),
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

  void _showEditQuantityDialog(BuildContext context, StockAuditLine line) {
    final controller = TextEditingController(text: line.physicalQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Audit: ${line.productName}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Physical Quantity'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text) ?? line.physicalQty;
              context.read<StockAuditBloc>().add(UpdateAuditLineQuantity(
                    auditId: line.auditId,
                    productId: line.productId,
                    physicalQty: qty,
                  ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String auditId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Audit?'),
        content: const Text('All progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
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
        title: const Text('Complete Audit?'),
        content: const Text('This will update your inventory stock levels.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              context.read<StockAuditBloc>().add(CompleteAudit(auditId));
              Navigator.pop(context);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
