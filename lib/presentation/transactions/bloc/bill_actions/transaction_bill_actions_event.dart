import 'package:equatable/equatable.dart';

sealed class TransactionBillActionsEvent extends Equatable {
  const TransactionBillActionsEvent();

  @override
  List<Object?> get props => [];
}

final class TransactionBillReplaceSignedRequested
    extends TransactionBillActionsEvent {
  const TransactionBillReplaceSignedRequested({
    required this.billId,
    required this.localFilePath,
  });

  final String billId;
  final String localFilePath;

  @override
  List<Object?> get props => [billId, localFilePath];
}

final class TransactionBillDeleteRequested extends TransactionBillActionsEvent {
  const TransactionBillDeleteRequested(this.billId);

  final String billId;

  @override
  List<Object?> get props => [billId];
}

final class TransactionBillActionsFeedbackConsumed
    extends TransactionBillActionsEvent {
  const TransactionBillActionsFeedbackConsumed();
}
