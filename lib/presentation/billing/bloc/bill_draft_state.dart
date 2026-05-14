import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';

class BillDraftState extends Equatable {
  const BillDraftState({this.lines = const <BillDraftLine>[]});

  final List<BillDraftLine> lines;

  double get subtotal => lines.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  BillDraftState copyWith({List<BillDraftLine>? lines}) {
    return BillDraftState(lines: lines ?? this.lines);
  }

  @override
  List<Object?> get props => [lines];
}
