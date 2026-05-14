import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class IncompleteTransactionsEvent extends Equatable {
  const IncompleteTransactionsEvent();

  @override
  List<Object?> get props => [];
}

final class IncompleteBillsReceived extends IncompleteTransactionsEvent {
  const IncompleteBillsReceived(this.bills);

  final List<Bill> bills;

  @override
  List<Object?> get props => [bills];
}

final class IncompleteSearchQueryChanged extends IncompleteTransactionsEvent {
  const IncompleteSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class IncompleteSelectedDateChanged extends IncompleteTransactionsEvent {
  const IncompleteSelectedDateChanged(this.date);

  final DateTime? date;

  @override
  List<Object?> get props => [date];
}

final class IncompleteSearchModeToggled extends IncompleteTransactionsEvent {
  const IncompleteSearchModeToggled();
}
