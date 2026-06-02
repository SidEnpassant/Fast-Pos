import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/analytics/business_analytics.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';

Bill _bill({
  double total = 100,
  double paid = 100,
  String status = 'complete',
  DateTime? createdAt,
  List<BillLineItem> lines = const [],
}) {
  return Bill(
    id: 'b1',
    customerName: 'Test',
    customerPhone: '',
    totalAmount: total,
    paidAmount: paid,
    paymentMethod: 'cash',
    paymentStatus: status,
    createdAt: createdAt ?? DateTime(2026, 5, 15),
    lineItems: lines,
  );
}

void main() {
  test('monthly revenue uses recognized amounts and local month', () {
    final bills = [
      _bill(
        total: 1000,
        paid: 1000,
        createdAt: DateTime(2026, 5, 10),
        lines: const [
          BillLineItem(productName: 'Book', quantity: 2, totalPrice: 500),
        ],
      ),
      _bill(
        total: 2000,
        paid: 500,
        status: 'partial',
        createdAt: DateTime(2026, 5, 20),
      ),
      _bill(
        total: 300,
        paid: 300,
        createdAt: DateTime(2026, 4, 28),
      ),
    ];

    final map = BusinessAnalytics.monthlyRevenueMap(bills);
    expect(map['May 2026'], 1500);
    expect(map['Apr 2026'], 300);
  });

  test('compute snapshot includes trends and inventory value', () {
    final now = DateTime(2026, 5, 20);
    final snapshot = BusinessAnalytics.compute(
      reference: now,
      bills: [
        _bill(createdAt: DateTime(2026, 5, 1)),
        _bill(createdAt: DateTime(2026, 4, 1)),
      ],
      expenses: [
        Expense(
          id: 'e1',
          userId: 'u',
          category: 'Rent',
          amount: 5000,
          expenseDate: DateTime(2026, 5, 5),
          createdAt: DateTime(2026, 5, 5),
        ),
      ],
      products: [
        Product(
          id: 'p1',
          userId: 'u',
          name: 'Item',
          price: 100,
          costPrice: 60,
          stockQuantity: 2,
          minStockThreshold: 5,
          updatedAt: now,
        ),
      ],
    );

    expect(snapshot.revenueTrend.current, greaterThan(0));
    expect(snapshot.expenseBreakdownThisMonth.first.category, 'Rent');
    expect(snapshot.inventory.lowStock, 1);
    expect(snapshot.inventory.retailValue, 200);
  });
}
