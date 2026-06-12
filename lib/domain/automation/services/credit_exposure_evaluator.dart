import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/analytics/customer_analytics.dart';

class CreditExposureAlert extends Equatable {
  const CreditExposureAlert({
    required this.customerKey,
    required this.customerName,
    this.phone,
    required this.outstandingCredit,
  });

  final String customerKey;
  final String customerName;
  final String? phone;
  final double outstandingCredit;

  @override
  List<Object?> get props =>
      [customerKey, customerName, phone, outstandingCredit];
}

abstract final class CreditExposureEvaluator {
  static List<CreditExposureAlert> evaluate(
    CustomerAnalyticsSnapshot snapshot, {
    double threshold = 5000,
  }) {
    return snapshot.withOutstandingCredit
        .where((e) => e.outstandingCredit >= threshold)
        .map(
          (e) => CreditExposureAlert(
            customerKey: e.key,
            customerName: e.name,
            phone: e.phone,
            outstandingCredit: e.outstandingCredit,
          ),
        )
        .toList();
  }
}
