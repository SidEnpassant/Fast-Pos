import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class CompleteTransactionsEvent extends Equatable {
  const CompleteTransactionsEvent();

  @override
  List<Object?> get props => [];
}

final class CompleteBillsReceived extends CompleteTransactionsEvent {
  const CompleteBillsReceived(this.bills);

  final List<Bill> bills;

  @override
  List<Object?> get props => [bills];
}

final class CompleteSearchQueryChanged extends CompleteTransactionsEvent {
  const CompleteSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CompleteDateRangeChanged extends CompleteTransactionsEvent {
  const CompleteDateRangeChanged(this.start, this.end);

  final DateTime? start;
  final DateTime? end;

  @override
  List<Object?> get props => [start, end];
}

final class CompleteSearchModeToggled extends CompleteTransactionsEvent {
  const CompleteSearchModeToggled();
}
