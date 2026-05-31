import 'package:flutter/material.dart';
import 'package:inventopos/domain/entities/bill.dart';

class CompleteTransactionBillCard extends StatelessWidget {
  const CompleteTransactionBillCard({
    super.key,
    required this.bill,
    required this.onShowBill,
    required this.onDelete,
  });

  final Bill bill;
  final VoidCallback onShowBill;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAmount = bill.totalAmount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        title: Text(
          bill.customerName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(bill.customerPhone),
            const SizedBox(height: 4),
            Text(
              'Amount: ₹${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment: ${bill.paymentMethod}'),
                const SizedBox(height: 12),
                ...bill.lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity}',
                          ),
                        ),
                        Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Show Bill'),
                      onPressed: onShowBill,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
