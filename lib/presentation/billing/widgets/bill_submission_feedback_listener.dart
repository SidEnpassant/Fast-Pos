import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_submission_state.dart';

/// Centralizes [BillSubmissionBloc] success/failure UI side-effects.
class BillSubmissionFeedbackListener extends StatelessWidget {
  const BillSubmissionFeedbackListener({
    super.key,
    required this.child,
    required this.onSuccess,
  });

  final Widget child;
  final void Function(BuildContext context, BillSubmissionSuccess success)
      onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillSubmissionBloc, BillSubmissionState>(
      listener: (context, submissionState) {
        if (submissionState is BillSubmissionSuccess) {
          onSuccess(context, submissionState);
          context.read<BillSubmissionBloc>().add(const BillSubmissionHandled());
        } else if (submissionState is BillSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(submissionState.message)),
          );
          context.read<BillSubmissionBloc>().add(const BillSubmissionHandled());
        }
      },
      child: child,
    );
  }
}
