import 'package:equatable/equatable.dart';

enum TransactionBillActionsPhase { idle, busy, success, failure }

class TransactionBillActionsState extends Equatable {
  const TransactionBillActionsState({
    this.phase = TransactionBillActionsPhase.idle,
    this.message,
  });

  final TransactionBillActionsPhase phase;
  final String? message;

  TransactionBillActionsState copyWith({
    TransactionBillActionsPhase? phase,
    String? message,
    bool clearMessage = false,
  }) {
    return TransactionBillActionsState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [phase, message];
}
