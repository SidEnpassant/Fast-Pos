import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_draft_event.dart';
import 'package:inventopos/presentation/billing_copilot/bloc/billing_copilot_bloc.dart';
import 'package:inventopos/presentation/billing_copilot/bloc/billing_copilot_event.dart';
import 'package:inventopos/presentation/billing_copilot/bloc/billing_copilot_state.dart';

void showBillingCopilotSheet(
  BuildContext context, {
  required String userId,
  required List<Product> products,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<BillingCopilotBloc>()
        ..add(BillingCopilotStarted(userId: userId, products: products)),
      child: const _BillingCopilotSheetBody(),
    ),
  );
}

class _BillingCopilotSheetBody extends StatelessWidget {
  const _BillingCopilotSheetBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: BlocBuilder<BillingCopilotBloc, BillingCopilotState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Billing Copilot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(state.transcript.isEmpty
                  ? 'Tap mic and say e.g. "2 chai 1 biscuit"'
                  : state.transcript),
              if (state.parseError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.parseError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (state.hasPendingLines) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text('Confirm lines to add:'),
                ...state.pendingCommand!.lines.map(
                  (l) => ListTile(
                    dense: true,
                    title: Text('${l.quantity}× ${l.productName}'),
                  ),
                ),
                FilledButton(
                  onPressed: () => _applyCommand(context, state.pendingCommand!),
                  child: const Text('Add to bill'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: state.parsing
                        ? null
                        : () => context
                            .read<BillingCopilotBloc>()
                            .add(const BillingCopilotListeningToggled()),
                    icon: Icon(
                      state.isListening ? Icons.mic : Icons.mic_none,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.parsing || state.transcript.trim().isEmpty
                          ? null
                          : () => context
                              .read<BillingCopilotBloc>()
                              .add(const BillingCopilotParseRequested()),
                      child: state.parsing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Parse with AI'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyCommand(BuildContext context, VoiceBillCommand command) {
    final draft = context.read<BillDraftBloc>();
    for (final line in command.lines) {
      draft.add(
        BillDraftLineAdded(
          BillDraftLine(
            name: line.productName,
            price: 0,
            quantity: line.quantity,
            productId: line.productId,
          ),
        ),
      );
    }
    Navigator.pop(context);
  }
}
