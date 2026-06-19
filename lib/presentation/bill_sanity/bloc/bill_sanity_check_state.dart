import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/automation/entities/bill_sanity_result.dart';

class BillSanityCheckState extends Equatable {
  const BillSanityCheckState({
    this.result,
    this.overridden = false,
  });

  final BillSanityResult? result;
  final bool overridden;

  bool get canProceed => overridden || result == null || !result!.hasWarnings;

  BillSanityCheckState copyWith({
    BillSanityResult? result,
    bool? overridden,
    bool clearResult = false,
  }) =>
      BillSanityCheckState(
        result: clearResult ? null : (result ?? this.result),
        overridden: overridden ?? this.overridden,
      );

  @override
  List<Object?> get props => [result, overridden];
}
