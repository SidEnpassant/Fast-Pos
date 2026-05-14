import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/billing/bill_submission.dart';

sealed class BillSubmissionState extends Equatable {
  const BillSubmissionState();

  @override
  List<Object?> get props => [];
}

class BillSubmissionIdle extends BillSubmissionState {
  const BillSubmissionIdle();
}

class BillSubmissionLoading extends BillSubmissionState {
  const BillSubmissionLoading();
}

class BillSubmissionSuccess extends BillSubmissionState {
  const BillSubmissionSuccess(this.result);

  final BillSubmissionResult result;

  @override
  List<Object?> get props => [result];
}

class BillSubmissionFailure extends BillSubmissionState {
  const BillSubmissionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
