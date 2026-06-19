import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/billing/validate_bill_line_quantity.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/inventory/unit_of_measure.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

/// Shared quantity sheet for scan flow and inventory picker.
/// Returns the confirmed line, or null if dismissed.
Future<BillDraftLine?> showBillLineQuantitySheet(
  BuildContext context, {
  required String name,
  required double price,
  required List<BillDraftLine> existingLines,
  String? productId,
  double initialQuantity = 1.0,
  int? editingIndex,
  String uom = 'piece',
}) {
  return showModalBottomSheet<BillDraftLine>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _BillLineQuantitySheet(
      name: name,
      price: price,
      productId: productId,
      initialQuantity: initialQuantity,
      editingIndex: editingIndex,
      existingLines: existingLines,
      uom: uom,
    ),
  );
}

class _BillLineQuantitySheet extends StatefulWidget {
  const _BillLineQuantitySheet({
    required this.name,
    required this.price,
    required this.existingLines,
    this.productId,
    required this.initialQuantity,
    this.editingIndex,
    required this.uom,
  });

  final String name;
  final double price;
  final String? productId;
  final double initialQuantity;
  final int? editingIndex;
  final List<BillDraftLine> existingLines;
  final String uom;

  @override
  State<_BillLineQuantitySheet> createState() => _BillLineQuantitySheetState();
}

class _BillLineQuantitySheetState extends State<_BillLineQuantitySheet> {
  late final TextEditingController _controller;
  double? _availableStock;
  String? _error;
  bool _loading = true;
  late final UnitOfMeasure _parsedUom;

  @override
  void initState() {
    super.initState();
    _parsedUom = UnitOfMeasureX.fromString(widget.uom);
    _controller = TextEditingController(
      text: _parsedUom.isDecimalUnit 
          ? widget.initialQuantity.toString() 
          : widget.initialQuantity.toInt().toString()
    );
    _loadStock();
  }

  Future<void> _loadStock() async {
    final pid = widget.productId;
    if (pid == null || pid.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final p = await context.read<ProductRepository>().findById(pid);
    if (mounted) {
      setState(() {
        _availableStock = p?.stockQuantity;
        _loading = false;
      });
      _validate();
    }
  }

  void _validate() {
    final qty = double.tryParse(_controller.text.trim()) ?? 0.0;
    final result = ValidateBillLineQuantity.validate(
      quantity: qty,
      availableStock: _availableStock,
      productId: widget.productId,
      existingLines: widget.existingLines,
      editingIndex: widget.editingIndex,
    );
    setState(() {
      _error = result.isValid ? null : result.errorMessage;
    });
  }

  void _submit() {
    final qty = double.tryParse(_controller.text.trim()) ?? 0.0;
    final result = ValidateBillLineQuantity.validate(
      quantity: qty,
      availableStock: _availableStock,
      productId: widget.productId,
      existingLines: widget.existingLines,
      editingIndex: widget.editingIndex,
    );
    if (!result.isValid) return;

    Navigator.pop(
      context,
      BillDraftLine(
        name: widget.name,
        price: widget.price,
        quantity: qty,
        productId: widget.productId,
        uom: widget.uom,
      ),
    );
  }

  void _setQty(double qty) {
    _controller.text = _parsedUom.isDecimalUnit ? '$qty' : '${qty.toInt()}';
    _validate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAvail = widget.productId != null && _availableStock != null
        ? ValidateBillLineQuantity.validate(
            quantity: 1.0,
            availableStock: _availableStock,
            productId: widget.productId,
            existingLines: widget.existingLines,
            editingIndex: widget.editingIndex,
          ).maxAllowed
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: theme.textTheme.titleLarge),
          Text(
            '₹${widget.price.toStringAsFixed(2)} per ${_parsedUom.symbol}',
            style: theme.textTheme.bodyMedium,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppShimmer(
                child: Column(
                  children: [
                    AppSkeletonText(height: 40),
                    SizedBox(height: 12),
                    AppSkeletonText(width: 150),
                  ],
                ),
              ),
            )
          else ...[
            if (_availableStock != null)
              Text(
                'In stock: $_availableStock ${_parsedUom.pluralLabel}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: _parsedUom.isDecimalUnit,
              ),
              inputFormatters: [
                if (!_parsedUom.isDecimalUnit)
                  FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Quantity',
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixText: _parsedUom.symbol,
              ),
              onChanged: (_) => _validate(),
            ),
            if (maxAvail != null && maxAvail > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+1'),
                    onPressed: () {
                      final q = (double.tryParse(_controller.text) ?? 0.0) + 1;
                      _setQty(q);
                    },
                  ),
                  ActionChip(
                    label: const Text('+5'),
                    onPressed: () {
                      final q = (double.tryParse(_controller.text) ?? 0.0) + 5;
                      _setQty(q);
                    },
                  ),
                  ActionChip(
                    label: Text('Max ($maxAvail)'),
                    onPressed: () => _setQty(maxAvail),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _error == null &&
                      (double.tryParse(_controller.text.trim()) ?? 0.0) > 0
                  ? _submit
                  : null,
              child:
                  Text(widget.editingIndex != null ? 'Update' : 'Add to bill'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens quantity sheet for a catalog [Product].
Future<BillDraftLine?> showBillLineQuantitySheetForProduct(
  BuildContext context,
  Product product, {
  required List<BillDraftLine> existingLines,
  int? editingIndex,
  double initialQuantity = 1.0,
}) =>
    showBillLineQuantitySheet(
      context,
      name: product.name,
      price: product.price,
      productId: product.id.isEmpty ? null : product.id,
      initialQuantity: initialQuantity,
      editingIndex: editingIndex,
      existingLines: existingLines,
      uom: product.uom,
    );

