import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/bill.dart';

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

final class AnalyticsBillsReceived extends AnalyticsEvent {
  const AnalyticsBillsReceived(this.bills);

  final List<Bill> bills;

  @override
  List<Object?> get props => [bills];
}

final class AnalyticsMonthSelected extends AnalyticsEvent {
  const AnalyticsMonthSelected(this.month);

  final String month;

  @override
  List<Object?> get props => [month];
}

final class AnalyticsChartToggled extends AnalyticsEvent {
  const AnalyticsChartToggled();
}
