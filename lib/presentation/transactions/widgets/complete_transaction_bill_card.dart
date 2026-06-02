import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_status_chip.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:intl/intl.dart';

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
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            title: Text(
              bill.customerName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bill.customerPhone.isNotEmpty)
                    Text(
                      bill.customerPhone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppStatusChip(
                        label: bill.paymentStatus,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fmt.format(bill.totalAmount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text('Payment: ${bill.paymentMethod}'),
                ],
              ),
              const SizedBox(height: 12),
              ...bill.lineItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} × ${item.quantity}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        fmt.format(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Show Bill'),
                      onPressed: onShowBill,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
