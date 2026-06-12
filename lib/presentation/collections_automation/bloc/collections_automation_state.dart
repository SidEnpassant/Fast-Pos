import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/automation/services/credit_exposure_evaluator.dart';
import 'package:inventopos/domain/entities/bill.dart';

class CollectionsAutomationState extends Equatable {
  const CollectionsAutomationState({
    this.overdueBills = const [],
    this.creditAlerts = const [],
    this.loading = false,
  });

  final List<Bill> overdueBills;
  final List<CreditExposureAlert> creditAlerts;
  final bool loading;

  CollectionsAutomationState copyWith({
    List<Bill>? overdueBills,
    List<CreditExposureAlert>? creditAlerts,
    bool? loading,
  }) =>
      CollectionsAutomationState(
        overdueBills: overdueBills ?? this.overdueBills,
        creditAlerts: creditAlerts ?? this.creditAlerts,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [overdueBills, creditAlerts, loading];
}
