import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/automation/services/credit_exposure_evaluator.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class CollectionsAutomationEvent extends Equatable {
  const CollectionsAutomationEvent();
  @override
  List<Object?> get props => [];
}

final class CollectionsAutomationStarted extends CollectionsAutomationEvent {
  const CollectionsAutomationStarted({
    required this.userId,
    required this.bills,
    required this.customers,
  });
  final String userId;
  final List<Bill> bills;
  final List<dynamic> customers;
  @override
  List<Object?> get props => [userId, bills];
}

final class CollectionsAutomationLoaded extends CollectionsAutomationEvent {
  const CollectionsAutomationLoaded({
    required this.overdueBills,
    required this.creditAlerts,
  });
  final List<Bill> overdueBills;
  final List<CreditExposureAlert> creditAlerts;
  @override
  List<Object?> get props => [overdueBills, creditAlerts];
}
