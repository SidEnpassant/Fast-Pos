import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/entities/credit_note.dart';
import 'package:inventopos/presentation/credit_notes/bloc/credit_notes_bloc.dart';
import 'package:inventopos/presentation/credit_notes/bloc/credit_notes_state.dart';

class CreditNotesScreen extends StatelessWidget {
  const CreditNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Credit Notes / Returns',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      body: BlocBuilder<CreditNotesBloc, CreditNotesState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonList(itemCount: 8);
          }

          if (state.notes.isEmpty) {
            return const AppEmptyState(
              icon: Icons.assignment_return_outlined,
              title: 'No returns yet',
              message: 'Processed returns and credit notes will appear here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.notes.length,
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return _CreditNoteCard(note: note);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/complete-transactions'),
        icon: const Icon(Icons.add),
        label: const Text('New Return'),
      ),
    );
  }
}

class _CreditNoteCard extends StatelessWidget {
  const _CreditNoteCard({required this.note});

  final CreditNote note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CN# ${note.creditNoteNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(note.returnDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (note.customerName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('Customer: ${note.customerName}'),
              ),
            Text('Refund Method: ${note.refundMethod.toUpperCase()}'),
            if (note.reason != null && note.reason!.isNotEmpty)
              Text('Reason: ${note.reason}'),
            const Divider(),
            ...note.lineItems.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${line.productName} x ${line.quantity}'),
                      Text('Rs. ${line.lineTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: Rs. ${note.totalRefundAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
