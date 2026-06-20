import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_barcode_scan_sheet.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/inventory/unit_of_measure.dart';
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
  final _conversionController = TextEditingController();
  final _hsnController = TextEditingController();
  final _gstController = TextEditingController(text: '0');

  UnitOfMeasure _uom = UnitOfMeasure.piece;
  String? _barcode;
  bool _isActive = true;
  bool _saving = false;
  Product? _existing;

  static const _fieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
  );

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
      _uom = UnitOfMeasureX.fromString(p.uom);
      _conversionController.text = p.conversionFactor?.toString() ?? '';
      _hsnController.text = p.hsnCode ?? '';
      _gstController.text = p.gstPercent.toString();
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
    _conversionController.dispose();
    _hsnController.dispose();
    _gstController.dispose();
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
    final stock = double.tryParse(_stockController.text) ?? 0.0;
    final minStock = double.tryParse(_minStockController.text) ?? 5.0;
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
            uom: _uom.name,
            conversionFactor: double.tryParse(_conversionController.text),
            hsnCode: _hsnController.text.trim().isEmpty
                ? null
                : _hsnController.text.trim(),
            gstPercent: double.tryParse(_gstController.text) ?? 0.0,
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
          uom: _uom.name,
          conversionFactor: double.tryParse(_conversionController.text),
          hsnCode: _hsnController.text.trim().isEmpty
              ? null
              : _hsnController.text.trim(),
          gstPercent: double.tryParse(_gstController.text) ?? 0.0,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;
    return AppScreenScaffold(
      title: isEdit ? 'Edit product' : 'Add product',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          AppSectionCard(
            title: 'Barcode',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_barcode != null)
                  Chip(
                    avatar: const Icon(Icons.qr_code, size: 18),
                    label: Text(_barcode!),
                  )
                else
                  Text(
                    'No barcode scanned',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan barcode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Product details',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Name *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _skuController,
                  decoration: _fieldDecoration.copyWith(labelText: 'SKU'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  decoration: _fieldDecoration.copyWith(labelText: 'Category'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Pricing & Tax',
            child: Column(
              children: [
                TextField(
                  controller: _priceController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Selling price *',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _costController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Cost price',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hsnController,
                        decoration:
                            _fieldDecoration.copyWith(labelText: 'HSN Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _gstController,
                        decoration: _fieldDecoration.copyWith(
                          labelText: 'GST %',
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Stock & Units',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UnitOfMeasure>(
                        initialValue: _uom,
                        decoration:
                            _fieldDecoration.copyWith(labelText: 'Unit (UOM)'),
                        items: UnitOfMeasure.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _uom = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stockController,
                        decoration: _fieldDecoration.copyWith(
                          labelText: 'Initial Stock',
                          suffixText: _uom.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minStockController,
                        decoration: _fieldDecoration.copyWith(
                          labelText: 'Min stock',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _conversionController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Conversion Factor (Optional)',
                    hintText: 'e.g. 12 for dozen to piece',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle:
                      const Text('Inactive products are hidden from billing'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const AppShimmer(
                    child: Text('Save product'),
                  )
                : const Text('Save product'),
          ),
        ),
      ),
    );
  }
}
