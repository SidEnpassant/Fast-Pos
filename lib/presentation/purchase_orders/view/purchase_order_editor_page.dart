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

    setState(() {
      _suppliers = suppliers;
      _products = products;
      _isLoading = false;
    });

    if (widget.purchaseOrderId != null) {
      // Load existing PO if editing
      // For simplicity in this demo, we assume we get the PO from the bloc state or repository
      // In a real app, you might want a dedicated use case or fetch it here.
    }
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
              subtitle: Text('Price: ₹${p.price}'),
              onTap: () {
                setState(() {
                  _lines.add(PurchaseOrderLine(
                    productId: p.id,
                    productName: p.name,
                    orderedQty: 1,
                    receivedQty: 0,
                    unitCost: p.costPrice ?? 0,
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
                    trailing: Text('₹${line.orderedQty * line.unitCost}'),
                    onLongPress: () {
                      setState(() {
                        _lines.removeAt(index);
                      });
                    },
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
