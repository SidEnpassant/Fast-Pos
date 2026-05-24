import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/presentation/dashboard/bloc/dashboard_hub_state.dart';

Bill _bill({
  required String status,
  required double total,
  double paid = 0,
  DateTime? createdAt,
}) {
  return Bill(
    id: '1',
    userId: 'u',
    businessName: 'Shop',
    customerName: 'A',
    customerPhone: '',
    lineItems: const [],
    totalAmount: total,
    paidAmount: paid,
    paymentMethod: 'cash',
    paymentStatus: status,
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  test('revenueToday sums complete and partial bills for today', () {
    final today = DateTime.now();
    final state = DashboardHubState(
      bills: [
        _bill(status: 'complete', total: 100, createdAt: today),
        _bill(status: 'partial', total: 200, paid: 50, createdAt: today),
        _bill(
          status: 'complete',
          total: 999,
          createdAt: today.subtract(const Duration(days: 2)),
        ),
      ],
      loading: false,
    );

    expect(state.revenueToday, 150);
    expect(state.billsToday, 2);
  });
}
