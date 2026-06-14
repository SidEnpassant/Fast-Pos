import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_inventory_picker_state.dart';
import 'package:inventopos/presentation/billing/widgets/bill_line_quantity_sheet.dart';

class BillInventoryPickerPage extends StatefulWidget {
  const BillInventoryPickerPage({
    super.key,
    this.existingDraftLines = const [],
  });

  final List<BillDraftLine> existingDraftLines;

  @override
  State<BillInventoryPickerPage> createState() =>
      _BillInventoryPickerPageState();
}

class _BillInventoryPickerPageState extends State<BillInventoryPickerPage> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<BillInventoryPickerBloc>().add(
            BillInventoryPickerStarted(uid),
          );
    }
  }

  Future<void> _onProductTap(Product product) async {
    final line = await showBillLineQuantitySheetForProduct(
      context,
      product,
      existingLines: widget.existingDraftLines,
    );
    if (line != null && mounted) {
      Navigator.pop(context, line);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select from inventory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search products…',
              onChanged: (q) => context
                  .read<BillInventoryPickerBloc>()
                  .add(BillInventoryPickerSearchChanged(q)),
            ),
          ),
          Expanded(
            child: BlocBuilder<BillInventoryPickerBloc, BillInventoryPickerState>(
              builder: (context, state) {
                if (state.loading) {
                  return const AppSkeletonList(itemCount: 10);
                }
                if (state.filteredProducts.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    message: 'Add items in Inventory first',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = state.filteredProducts[index];
                    return _ProductTile(
                      product: p,
                      onTap: () => _onProductTap(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        onTap: onTap,
        title: Text(product.name),
        subtitle: Text(
          '₹${product.price.toStringAsFixed(2)} · Stock: ${product.stockQuantity}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
