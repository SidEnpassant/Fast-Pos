import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/billing/bill_revenue.dart';
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

  test('BillRevenue uses local calendar day for UTC timestamps', () {
    final localMorning = DateTime(2026, 6, 1, 9);
    final utcBillTime = localMorning.toUtc();
    final bill = _bill(
      status: 'complete',
      total: 500,
      createdAt: utcBillTime,
    );

    expect(
      BillRevenue.isSameCalendarDay(bill, localMorning),
      isTrue,
    );
    expect(BillRevenue.recognizedAmount(bill), 500);
  });

  test('BillRevenue recognizes uppercase payment status', () {
    final bill = _bill(status: 'Complete', total: 250);
    expect(BillRevenue.recognizedAmount(bill), 250);
  });
}
