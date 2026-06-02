import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_barcode_scan_sheet.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_filter_chip_bar.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_bloc.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_event.dart';
import 'package:inventopos/presentation/inventory/bloc/inventory_state.dart';
import 'package:inventopos/presentation/inventory/widgets/product_list_tile.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<InventoryBloc>().add(InventoryStarted(uid));
    }
  }

  @override
  void activate() {
    super.activate();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      unawaited(context.read<ProductRepository>().fetchProductsForUser(uid));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _filterIndex(InventoryFilter f) {
    switch (f) {
      case InventoryFilter.all:
        return 0;
      case InventoryFilter.lowStock:
        return 1;
      case InventoryFilter.outOfStock:
        return 2;
    }
  }

  InventoryFilter _filterFromIndex(int i) {
    switch (i) {
      case 1:
        return InventoryFilter.lowStock;
      case 2:
        return InventoryFilter.outOfStock;
      default:
        return InventoryFilter.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final stockValue = state.allProducts.fold<double>(
            0,
            (s, p) => s + p.price * p.stockQuantity,
          );
          final lowCount = state.lowStockProducts.length;
          final outCount = state.allProducts
              .where((p) => p.stockQuantity <= 0)
              .length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: scheme.surfaceContainerLowest,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SegmentedButton<InventoryViewMode>(
                      segments: const [
                        ButtonSegment(
                          value: InventoryViewMode.list,
                          icon: Icon(Icons.view_list, size: 20),
                        ),
                        ButtonSegment(
                          value: InventoryViewMode.grid,
                          icon: Icon(Icons.grid_view, size: 20),
                        ),
                      ],
                      selected: {state.viewMode},
                      onSelectionChanged: (s) => context
                          .read<InventoryBloc>()
                          .add(InventoryViewModeChanged(s.first)),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'Products',
                            value: '${state.allProducts.length}',
                            icon: Icons.category,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'Stock value',
                            value: fmt.format(stockValue),
                            icon: Icons.store,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'Low stock',
                            value: '$lowCount',
                            icon: Icons.warning_amber,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: AppMetricCard.heightCompact,
                          child: AppMetricCard(
                            title: 'Out of stock',
                            value: '$outCount',
                            icon: Icons.remove_shopping_cart,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search products',
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      scheme.surfaceContainerLow,
                    ),
                    onChanged: (q) => context
                        .read<InventoryBloc>()
                        .add(InventorySearchQueryChanged(q)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AppFilterChipBar(
                  labels: const ['All', 'Low stock', 'Out of stock'],
                  selectedIndex: _filterIndex(state.filter),
                  onSelected: (i) => context.read<InventoryBloc>().add(
                        InventoryFilterChanged(_filterFromIndex(i)),
                      ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (state.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.filteredProducts.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products',
                    message: 'Add your first product or scan a barcode',
                    actionLabel: 'Add product',
                    onAction: () => context.push('/inventory/editor'),
                  ),
                )
              else if (state.viewMode == InventoryViewMode.grid)
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProductGridCard(
                        product: state.filteredProducts[i],
                        onTap: () => context.push(
                          '/inventory/editor',
                          extra: state.filteredProducts[i].id,
                        ),
                      ),
                      childCount: state.filteredProducts.length,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ProductListTile(
                      product: state.filteredProducts[i],
                      onTap: () => context.push(
                        '/inventory/editor',
                        extra: state.filteredProducts[i].id,
                      ),
                    ),
                    childCount: state.filteredProducts.length,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFabMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
    );
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add product'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/inventory/editor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan to add'),
              onTap: () async {
                Navigator.pop(ctx);
                final code = await showAppBarcodeScanSheet(
                  context,
                  title: 'Scan product barcode',
                );
                if (code != null && context.mounted) {
                  context.push('/inventory/editor');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import CSV'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/import-export');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = product;
    final low = p.isLowStock;
    final out = p.stockQuantity <= 0;
    final statusColor = out
        ? theme.colorScheme.error
        : low
            ? Colors.orange.shade800
            : Colors.green.shade700;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '₹${p.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: p.minStockThreshold > 0
                    ? (p.stockQuantity / (p.minStockThreshold * 2))
                        .clamp(0.0, 1.0)
                    : 1,
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock ${p.stockQuantity}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
