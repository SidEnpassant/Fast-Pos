import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_status_chip.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/collections_automation/widgets/bill_whatsapp_action_button.dart';
import 'package:inventopos/presentation/transactions/widgets/transaction_amount_row.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingTransactionBillCard extends StatelessWidget {
  const PendingTransactionBillCard({
    super.key,
    required this.bill,
    required this.onUpdatePayment,
    required this.onShowBill,
  });

  final Bill bill;
  final VoidCallback onUpdatePayment;
  final VoidCallback onShowBill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAmount = bill.totalAmount;
    final paidAmount = bill.paidAmount;
    final remainingAmount = totalAmount - paidAmount;
    final phone = bill.customerPhone.isEmpty ? 'N/A' : bill.customerPhone;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.receipt_long,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.customerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusChip(
                    label: 'Partial',
                    color: Colors.orange.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TransactionAmountRow(
                label: 'Total amount',
                amount: totalAmount,
              ),
              TransactionAmountRow(
                label: 'Amount paid',
                amount: paidAmount,
                valueColor: Colors.green.shade700,
              ),
              TransactionAmountRow(
                label: 'Remaining',
                amount: remainingAmount,
                valueColor: theme.colorScheme.error,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (remainingAmount > 0)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Update payment'),
                        onPressed: onUpdatePayment,
                      ),
                    ),
                  if (remainingAmount > 0) const SizedBox(width: 8),
                  if (remainingAmount > 0)
                    BillWhatsAppActionButton(
                      bill: bill,
                      userId:
                          Supabase.instance.client.auth.currentUser?.id ?? '',
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Show Bill'),
                      onPressed: onShowBill,
                    ),
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
