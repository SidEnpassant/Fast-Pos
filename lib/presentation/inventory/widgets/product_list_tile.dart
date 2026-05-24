import 'package:flutter/material.dart';
import 'package:inventopos/domain/entities/product.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;
    return ListTile(
      onTap: onTap,
      title: Text(product.name),
      subtitle: Text(
        '₹${product.price.toStringAsFixed(2)} · Stock ${product.stockQuantity}',
      ),
      trailing: low
          ? const Chip(
              label: Text('Low'),
              backgroundColor: Colors.orange,
            )
          : Text(product.barcode ?? ''),
    );
  }
}
