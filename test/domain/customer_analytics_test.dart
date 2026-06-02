import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/analytics/customer_analytics.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/customer.dart';

Bill _bill({
  required String name,
  String phone = '',
  String status = 'complete',
  double total = 100,
  double paid = 100,
  DateTime? createdAt,
}) {
  return Bill(
    id: 'b-$name',
    customerName: name,
    customerPhone: phone,
    totalAmount: total,
    paidAmount: paid,
    paymentMethod: 'cash',
    paymentStatus: status,
    createdAt: createdAt ?? DateTime(2026, 6, 15),
    lineItems: const [],
  );
}

void main() {
  test('computes top customers and pending collections', () {
    final now = DateTime(2026, 6, 20);
    final snapshot = CustomerAnalytics.compute(
      reference: now,
      customers: [
        Customer(
          id: 'c1',
          userId: 'u',
          name: 'Alice',
          phone: '9876543210',
          creditBalance: 500,
          updatedAt: now,
        ),
      ],
      bills: [
        _bill(name: 'Alice', phone: '9876543210', total: 1000, paid: 1000),
        _bill(
          name: 'Bob',
          phone: '9123456789',
          status: 'partial',
          total: 2000,
          paid: 500,
        ),
        _bill(
          name: 'Alice',
          phone: '9876543210',
          total: 500,
          paid: 500,
          createdAt: DateTime(2026, 5, 10),
        ),
      ],
    );

    expect(snapshot.totalCustomers, greaterThanOrEqualTo(2));
    expect(snapshot.activeThisMonth, 2);
    expect(snapshot.pendingFromPartialBills, 1500);
    expect(snapshot.topByRevenueThisMonth.first.name, 'Alice');
    expect(snapshot.withOutstandingCredit.first.outstandingCredit, 500);
  });
}
