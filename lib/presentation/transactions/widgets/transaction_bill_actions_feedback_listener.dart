import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_bloc.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_event.dart';
import 'package:inventopos/presentation/transactions/bloc/bill_actions/transaction_bill_actions_state.dart';

/// Listens for completed [TransactionBillActionsBloc] mutations (snackbar + dialog).
class TransactionBillActionsFeedbackListener extends StatelessWidget {
  const TransactionBillActionsFeedbackListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBillActionsBloc,
        TransactionBillActionsState>(
      listenWhen: (p, c) =>
          p.phase == TransactionBillActionsPhase.busy &&
          (c.phase == TransactionBillActionsPhase.success ||
              c.phase == TransactionBillActionsPhase.failure),
      listener: (ctx, s) {
        if (Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop();
        }
        final msg = s.message;
        if (msg != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: s.phase == TransactionBillActionsPhase.failure
                  ? Colors.red
                  : Colors.green,
            ),
          );
        }
        ctx.read<TransactionBillActionsBloc>().add(
              const TransactionBillActionsFeedbackConsumed(),
            );
      },
      child: child,
    );
  }
}
