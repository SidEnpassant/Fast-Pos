import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';

sealed class BillSubmissionEvent extends Equatable {
  const BillSubmissionEvent();

  @override
  List<Object?> get props => [];
}

class BillSubmissionRequested extends BillSubmissionEvent {
  const BillSubmissionRequested(this.draft);

  final BillSubmissionDraft draft;

  @override
  List<Object?> get props => [draft];
}

class BillSubmissionHandled extends BillSubmissionEvent {
  const BillSubmissionHandled();
}
