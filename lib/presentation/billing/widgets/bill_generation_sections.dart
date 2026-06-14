import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/widgets/bill_form_components.dart';
import 'package:inventopos/presentation/billing/widgets/bill_line_quantity_sheet.dart';
import 'package:inventopos/presentation/billing/widgets/repeat_order_suggestions.dart';

class BillGenerationCustomerSection extends StatelessWidget {
  const BillGenerationCustomerSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.isListening,
    required this.onMicPressed,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isListening;
  final VoidCallback onMicPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BillSectionCard(
      title: 'Customer Details',
      icon: Icons.person_outline,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextFormField(
                controller: nameController,
                decoration: billGenerationInputDecoration(
                  'Customer Name',
                  Icons.person,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onMicPressed,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: phoneController,
            decoration: billGenerationInputDecoration(
              'Phone Number',
              Icons.phone,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter phone number';
              }
              if (value!.length != 10) {
                return 'Please enter valid phone number';
              }
              return null;
            },
          ),
          const RepeatOrderSuggestions(),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}

class BillGenerationProductsSection extends StatelessWidget {
  const BillGenerationProductsSection({
    super.key,
    required this.lines,
    required this.totalAmount,
    required this.onAddProduct,
  });

  final List<BillDraftLine> lines;
  final double totalAmount;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return BillSectionCard(
      title: 'Products',
      icon: Icons.shopping_cart_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lines.length} item${lines.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (lines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No products added yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Scan barcode or add manually',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < lines.length; index++)
                  _BillDraftLineTile(
                    key: ValueKey(
                      'bill-line-${lines[index].name}-$index-${lines.length}',
                    ),
                    line: lines[index],
                    index: index,
                  ),
              ],
            ),
          if (lines.isNotEmpty) ...[
            const Divider(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fmt.format(totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 200));
  }
}

class BillGenerationPaymentSection extends StatelessWidget {
  const BillGenerationPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    required this.totalAmount,
    required this.onPaymentMethodChanged,
    required this.onPaymentStatusChanged,
    required this.onPaidAmountChanged,
  });

  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final double totalAmount;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<String?> onPaymentStatusChanged;
  final ValueChanged<double> onPaidAmountChanged;

  @override
  Widget build(BuildContext context) {
    return BillSectionCard(
      title: 'Payment Details',
      icon: Icons.payment_outlined,
      child: Column(
        children: [
          BillGenerationDropdownField(
            label: 'Payment Method',
            value: paymentMethod,
            items: const {
              'cash': 'Cash Payment',
              'upi': 'UPI Payment',
            },
            prefixIcon: Icons.payments,
            onChanged: onPaymentMethodChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          BillGenerationDropdownField(
            label: 'Payment Status',
            value: paymentStatus,
            items: const {
              'complete': 'Fully Paid',
              'partial': 'Partially Paid',
            },
            prefixIcon: Icons.check_circle,
            onChanged: onPaymentStatusChanged,
          ),
          if (paymentStatus == 'partial') ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: paidAmount.toString(),
              decoration: billGenerationInputDecoration(
                'Paid Amount',
                Icons.money,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter paid amount';
                }
                final amount = double.tryParse(value!);
                if (amount == null) {
                  return 'Please enter valid amount';
                }
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                if (amount > totalAmount) {
                  return 'Amount cannot be greater than total';
                }
                return null;
              },
              onChanged: (value) {
                onPaidAmountChanged(double.tryParse(value) ?? 0);
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 400));
  }
}

class _BillDraftLineTile extends StatelessWidget {
  const _BillDraftLineTile({
    super.key,
    required this.line,
    required this.index,
  });

  final BillDraftLine line;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        line.name.isNotEmpty ? line.name[0].toUpperCase() : '?';
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Slidable(
        key: ValueKey('slidable-$index'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                context.read<BillDraftBloc>().add(
                      BillDraftLineRemoved(index),
                    );
              },
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ],
        ),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              line.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${fmt.format(line.price)} × ${line.quantity}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              fmt.format(line.price * line.quantity),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: () async {
              final draftLines = context.read<BillDraftBloc>().state.lines;
              final updated = await showBillLineQuantitySheet(
                context,
                name: line.name,
                price: line.price,
                productId: line.productId,
                initialQuantity: line.quantity,
                editingIndex: index,
                existingLines: draftLines,
              );
              if (updated != null && context.mounted) {
                context.read<BillDraftBloc>().add(
                      BillDraftLineUpdated(index, updated),
                    );
              }
            },
          ),
        ),
      ),
    );
  }
}
