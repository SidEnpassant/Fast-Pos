import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:intl/intl.dart';

class AnalyticsInventoryContent extends StatelessWidget {
  const AnalyticsInventoryContent({
    super.key,
    required this.inventory,
    this.loading = false,
  });

  final InventoryInsightsSnapshot inventory;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (inventory.totalSkus == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No products yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add products in Inventory to track stock value and alerts.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/app/inventory'),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Open inventory'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            AppMetricCard(
              title: 'Total SKUs',
              value: '${inventory.totalSkus}',
              icon: Icons.category,
              color: Colors.indigo,
            ),
            AppMetricCard(
              title: 'Stock value (retail)',
              value: fmt.format(inventory.retailValue),
              icon: Icons.store,
              color: Colors.teal,
            ),
            AppMetricCard(
              title: 'Out of stock',
              value: '${inventory.outOfStock}',
              icon: Icons.remove_shopping_cart,
              color: Colors.red,
            ),
            AppMetricCard(
              title: 'Low stock',
              value: '${inventory.lowStock}',
              icon: Icons.warning_amber,
              color: Colors.orange,
            ),
          ],
        ),
        if (inventory.costValue > 0) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Cost basis',
            child: Text(
              'Estimated inventory cost: ${fmt.format(inventory.costValue)} '
              '(products with cost price set)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'Stock health',
          child: _StockHealthChart(
            inStock: inventory.inStock,
            lowStock: inventory.lowStock,
            outOfStock: inventory.outOfStock,
          ),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: 'Restock priority',
          actionLabel: 'Inventory',
          onAction: () => context.go('/app/inventory'),
          child: inventory.lowStockItems.isEmpty
              ? Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All products are above minimum stock levels.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: inventory.lowStockItems.map((p) {
                    return _LowStockTile(product: p, fmt: fmt);
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _StockHealthChart extends StatelessWidget {
  const _StockHealthChart({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  final int inStock;
  final int lowStock;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    final total = inStock + lowStock + outOfStock;
    if (total == 0) return const Text('No data');

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (inStock > 0)
                  Expanded(
                    flex: inStock,
                    child: Container(color: Colors.green),
                  ),
                if (lowStock > 0)
                  Expanded(
                    flex: lowStock,
                    child: Container(color: Colors.orange),
                  ),
                if (outOfStock > 0)
                  Expanded(
                    flex: outOfStock,
                    child: Container(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _HealthRow('Healthy', inStock, Colors.green, total),
        _HealthRow('Low', lowStock, Colors.orange, total),
        _HealthRow('Out', outOfStock, Colors.red, total),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow(this.label, this.count, this.color, this.total);

  final String label;
  final int count;
  final Color color;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$count ($pct%)'),
        ],
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product, required this.fmt});

  final InventoryProductRow product;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertColor =
        product.isOutOfStock ? Colors.red : Colors.orange.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                fmt.format(product.price),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            product.isOutOfStock
                ? 'Out of stock · reorder min ${product.minStockThreshold}'
                : 'Stock ${product.stockQuantity} / min ${product.minStockThreshold}',
            style: theme.textTheme.bodySmall?.copyWith(color: alertColor),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: product.fillRatio.clamp(0.05, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: alertColor,
            ),
          ),
        ],
      ),
    );
  }
}
