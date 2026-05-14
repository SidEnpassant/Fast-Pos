import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';

sealed class BillDraftEvent extends Equatable {
  const BillDraftEvent();

  @override
  List<Object?> get props => [];
}

class BillDraftLineAdded extends BillDraftEvent {
  const BillDraftLineAdded(this.line);

  final BillDraftLine line;

  @override
  List<Object?> get props => [line];
}

class BillDraftLineRemoved extends BillDraftEvent {
  const BillDraftLineRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class BillDraftCleared extends BillDraftEvent {
  const BillDraftCleared();
}
