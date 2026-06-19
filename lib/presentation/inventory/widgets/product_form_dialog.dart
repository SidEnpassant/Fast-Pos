import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_bloc.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_event.dart';

Future<void> showProductFormDialog(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final barcodeCtrl = TextEditingController();
  final minCtrl = TextEditingController(text: '5');

  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: barcodeCtrl,
                decoration: const InputDecoration(labelText: 'Barcode'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min threshold'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final uid = context.read<AuthRepository>().currentSession?.userId;
              if (uid == null) return;
              final product =
                  await context.read<ProductRepository>().createProduct(
                        userId: uid,
                        name: nameCtrl.text.trim(),
                        barcode: barcodeCtrl.text.trim().isEmpty
                            ? null
                            : barcodeCtrl.text.trim(),
                        price: double.tryParse(priceCtrl.text) ?? 0.0,
                        stockQuantity: double.tryParse(stockCtrl.text) ?? 0.0,
                        minStockThreshold: double.tryParse(minCtrl.text) ?? 5.0,
                      );
              if (ctx.mounted) {
                context
                    .read<InventoryBloc>()
                    .add(InventoryProductSaved(product));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  } finally {
    nameCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    barcodeCtrl.dispose();
    minCtrl.dispose();
  }
}
