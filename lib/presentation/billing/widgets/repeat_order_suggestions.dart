import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing/bloc/repeat_order_bloc.dart';

class RepeatOrderSuggestions extends StatelessWidget {
  const RepeatOrderSuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<RepeatOrderBloc, RepeatOrderState>(
      builder: (context, state) {
        if (state.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          );
        }
        final template = state.template;
        if (template == null || template.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Frequently ordered',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: template.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text('${item.productName} (x${item.avgQuantity})'),
                      onPressed: () {
                        context.read<BillDraftBloc>().add(
                              BillDraftLineAdded(
                                BillDraftLine(
                                  productId: '', // We don't have ID here, using name as key or similar
                                  name: item.productName,
                                  price: item.lastPrice,
                                  quantity: item.avgQuantity,
                                ),
                              ),
                            );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
