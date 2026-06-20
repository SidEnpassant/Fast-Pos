import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/entities/purchase_order.dart';
import 'package:inventopos/domain/entities/supplier.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/supplier_repository.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_bloc.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_event.dart';
import 'package:inventopos/presentation/purchase_orders/bloc/purchase_order_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PurchaseOrderEditorPage extends StatefulWidget {
  final String? purchaseOrderId;

  const PurchaseOrderEditorPage({super.key, this.purchaseOrderId});

  @override
  State<PurchaseOrderEditorPage> createState() => _PurchaseOrderEditorPageState();
}

class _PurchaseOrderEditorPageState extends State<PurchaseOrderEditorPage> {
  Supplier? _selectedSupplier;
  final List<PurchaseOrderLine> _lines = [];
  final TextEditingController _notesController = TextEditingController();
  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final supplierRepo = context.read<SupplierRepository>();
    final productRepo = context.read<ProductRepository>();

    final suppliers = await supplierRepo.watchSuppliersForUser(userId).first;
    final products = await productRepo.watchProductsForUser(userId).first;

    PurchaseOrder? existingPo;
    if (widget.purchaseOrderId != null) {
      final bloc = context.read<PurchaseOrderBloc>();
      PurchaseOrderState state = bloc.state;
      if (state.status != PurchaseOrderStatus.success) {
        state = await bloc.stream.firstWhere((s) => s.status == PurchaseOrderStatus.success);
      }
      try {
        existingPo = state.orders.firstWhere((o) => o.id == widget.purchaseOrderId);
      } catch (_) {}
    }

    setState(() {
      _suppliers = suppliers;
      _products = products;
      
      if (existingPo != null) {
        try {
          _selectedSupplier = suppliers.firstWhere((s) => s.id == existingPo!.supplierId);
        } catch (_) {}
        _notesController.text = existingPo.notes ?? '';
        _lines.clear();
        _lines.addAll(existingPo.lineItems);
      }

      _isLoading = false;
    });
  }

  void _addLine() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final p = _products[index];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('Cost: ₹${p.costPrice ?? p.price}'),
              onTap: () {
                setState(() {
                  _lines.add(PurchaseOrderLine(
                    productId: p.id,
                    productName: p.name,
                    orderedQty: 1,
                    receivedQty: 0,
                    unitCost: p.costPrice ?? p.price,
                    uom: p.uom,
                  ));
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  void _editLine(int index) {
    final line = _lines[index];
    final qtyController = TextEditingController(text: line.orderedQty.toString());
    final costController = TextEditingController(text: line.unitCost.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit ${line.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Ordered Qty'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Unit Cost'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? line.orderedQty;
                final cost = double.tryParse(costController.text) ?? line.unitCost;
                setState(() {
                  _lines[index] = PurchaseOrderLine(
                    productId: line.productId,
                    productName: line.productName,
                    orderedQty: qty,
                    receivedQty: line.receivedQty,
                    unitCost: cost,
                    uom: line.uom,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  double get _totalAmount => _lines.fold(0, (sum, item) => sum + (item.orderedQty * item.unitCost));

  void _savePO() {
    if (_selectedSupplier == null || _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier and add items')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final po = PurchaseOrder(
      id: widget.purchaseOrderId ?? const Uuid().v4(),
      userId: userId,
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      status: 'PENDING',
      orderDate: DateTime.now(),
      totalAmount: _totalAmount,
      notes: _notesController.text,
      lineItems: _lines,
    );

    if (widget.purchaseOrderId == null) {
      context.read<PurchaseOrderBloc>().add(PurchaseOrderCreated(po));
    } else {
      context.read<PurchaseOrderBloc>().add(PurchaseOrderUpdated(po));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScreenScaffold(
        title: 'Edit Purchase Order',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: widget.purchaseOrderId == null ? 'New Purchase Order' : 'Edit Purchase Order',
      actions: [
        IconButton(
          onPressed: _savePO,
          icon: const Icon(Icons.save),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Supplier>(
              initialValue: _selectedSupplier,
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: _suppliers.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSupplier = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return ListTile(
                    title: Text(line.productName),
                    subtitle: Text('Qty: ${line.orderedQty} x ₹${line.unitCost}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${line.orderedQty * line.unitCost}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editLine(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _lines.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '₹$_totalAmount',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
