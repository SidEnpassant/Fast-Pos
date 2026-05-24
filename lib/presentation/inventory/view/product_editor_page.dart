import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_barcode_scan_sheet.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class ProductEditorPage extends StatefulWidget {
  const ProductEditorPage({super.key, this.productId});

  final String? productId;

  @override
  State<ProductEditorPage> createState() => _ProductEditorPageState();
}

class _ProductEditorPageState extends State<ProductEditorPage> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '5');
  String? _barcode;
  bool _isActive = true;
  bool _saving = false;
  Product? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.productId == null) return;
    final repo = context.read<ProductRepository>();
    final p = await repo.findById(widget.productId!);
    if (p == null || !mounted) return;
    setState(() {
      _existing = p;
      _nameController.text = p.name;
      _skuController.text = p.sku ?? '';
      _categoryController.text = p.category ?? '';
      _priceController.text = p.price.toString();
      _costController.text = p.costPrice?.toString() ?? '';
      _stockController.text = p.stockQuantity.toString();
      _minStockController.text = p.minStockThreshold.toString();
      _barcode = p.barcode;
      _isActive = p.isActive;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await showAppBarcodeScanSheet(context, title: 'Scan barcode');
    if (code != null) setState(() => _barcode = code);
  }

  Future<void> _save() async {
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid == null) return;
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and price required')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<ProductRepository>();
    try {
      if (_existing != null) {
        await repo.updateProduct(
          Product(
            id: _existing!.id,
            userId: _existing!.userId,
            name: name,
            sku: _skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim(),
            barcode: _barcode,
            price: price,
            costPrice: double.tryParse(_costController.text),
            stockQuantity: stock,
            minStockThreshold: minStock,
            category: _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            isActive: _isActive,
            velocityEma: _existing!.velocityEma,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await repo.createProduct(
          userId: uid,
          name: name,
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          barcode: _barcode,
          price: price,
          costPrice: double.tryParse(_costController.text),
          stockQuantity: stock,
          minStockThreshold: minStock,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add product' : 'Edit product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_barcode != null)
            Chip(
              avatar: const Icon(Icons.qr_code),
              label: Text(_barcode!),
            )
          else
            const Chip(label: Text('No barcode scanned')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan barcode'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _skuController,
            decoration: const InputDecoration(labelText: 'SKU'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Selling price *',
              prefixText: '₹',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costController,
            decoration: const InputDecoration(
              labelText: 'Cost price',
              prefixText: '₹',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minStockController,
                  decoration: const InputDecoration(labelText: 'Min stock'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save product'),
          ),
        ),
      ),
    );
  }
}
