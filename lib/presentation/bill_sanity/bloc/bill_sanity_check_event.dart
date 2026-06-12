import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/automation/entities/bill_sanity_result.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class BillSanityCheckEvent extends Equatable {
  const BillSanityCheckEvent();
  @override
  List<Object?> get props => [];
}

final class BillSanityCheckRequested extends BillSanityCheckEvent {
  const BillSanityCheckRequested({
    required this.lines,
    required this.draftTotal,
    required this.recentBills,
  });
  final List<BillDraftLine> lines;
  final double draftTotal;
  final List<Bill> recentBills;
  @override
  List<Object?> get props => [lines, draftTotal];
}

final class BillSanityCheckOverrideConfirmed extends BillSanityCheckEvent {
  const BillSanityCheckOverrideConfirmed();
}

final class BillSanityCheckResultReceived extends BillSanityCheckEvent {
  const BillSanityCheckResultReceived(this.result);
  final BillSanityResult result;
  @override
  List<Object?> get props => [result];
}
