import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/returns/bloc/return_bloc.dart';
import 'package:inventopos/presentation/returns/bloc/return_event.dart';
import 'package:inventopos/presentation/returns/bloc/return_state.dart';

class ReturnScreen extends StatelessWidget {
  const ReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReturnBloc, ReturnState>(
      listenWhen: (p, c) =>
          p.success != c.success || p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Return processed successfully')),
          );
          context.pop();
        }
      },
      child: AppScreenScaffold(
        title: 'Return Items',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: BlocBuilder<ReturnBloc, ReturnState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressPadding());
            }

            final bill = state.originalBill;
            if (bill == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No bill selected',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'To process a return, please select a completed bill from your Transactions.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () {
                          context.go('/complete-transactions');
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Go to Transactions'),
                      )
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppSectionCard(
                  title: 'Original Bill: ${bill.displayBillNumber ?? 'N/A'}',
                  child: Column(
                    children: bill.lineItems.map((line) {
                      if (line.productId == null) {
                        return const SizedBox.shrink(); // Cannot return items without ID
                      }
                      final retQty = state.returnQuantities[line.productId!] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(line.productName),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Purchased: ${line.quantity}'),
                            ),
                            Expanded(
                              flex: 1,
                              child: DropdownButton<double>(
                                value: retQty,
                                isExpanded: true,
                                items: List.generate((line.quantity.toInt()) + 1, (index) {
                                  final q = index.toDouble();
                                  return DropdownMenuItem(
                                    value: q,
                                    child: Text(q.toString()),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<ReturnBloc>().add(
                                      ReturnQuantityChanged(line.productId!, val),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSectionCard(
                  title: 'Refund Details',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: state.returnReason,
                        decoration: const InputDecoration(labelText: 'Reason'),
                        items: ['Customer Request', 'Defective', 'Wrong Item']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            context.read<ReturnBloc>().add(ReturnReasonChanged(val));
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: state.refundMethod,
                        decoration: const InputDecoration(labelText: 'Refund Method'),
                        items: ['cash', 'credit', 'adjustment']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            context.read<ReturnBloc>().add(RefundMethodChanged(val));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Total Refund: Rs. ${state.totalRefundAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.right,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<ReturnBloc, ReturnState>(
          builder: (context, state) {
            if (state.originalBill == null) {
              return const SizedBox.shrink();
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed: state.submitting || state.returnQuantities.isEmpty
                      ? null
                      : () => context.read<ReturnBloc>().add(const ReturnSubmitted()),
                  child: state.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Process Return'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CircularProgressPadding extends StatelessWidget {
  const CircularProgressPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: CircularProgressIndicator(),
    );
  }
}
