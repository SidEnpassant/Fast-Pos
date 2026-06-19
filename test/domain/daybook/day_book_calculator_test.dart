import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/daybook/day_book_calculator.dart';
import 'package:inventopos/domain/entities/cash_entry.dart';

void main() {
  group('DayBookCalculator', () {
    final entry1 = CashEntry(
      id: '1',
      userId: 'u1',
      entryDate: DateTime(2023, 1, 1, 10),
      type: 'sale_cash',
      amount: 1000,
      createdAt: DateTime.now(),
    );
    final entry2 = CashEntry(
      id: '2',
      userId: 'u1',
      entryDate: DateTime(2023, 1, 1, 11),
      type: 'expense',
      amount: 200,
      createdAt: DateTime.now(),
    );
    final entry3 = CashEntry(
      id: '3',
      userId: 'u1',
      entryDate: DateTime(2023, 1, 1, 12),
      type: 'payment_received',
      amount: 500,
      createdAt: DateTime.now(),
    );

    test('computeDayBook calculates correct totals and balance', () {
      final summary = DayBookCalculator.computeDayBook(
        [entry1, entry2, entry3],
        5000, // opening balance
        DateTime(2023, 1, 1),
      );

      expect(summary.cashIn, 1500.0); // 1000 + 500
      expect(summary.cashOut, 200.0);
      expect(summary.openingBalance, 5000.0);
      expect(summary.closingBalance, 6300.0); // 5000 + 1500 - 200
    });

    test('computeRunningBalance correctly tracks chronological balance', () {
      final result = DayBookCalculator.computeRunningBalance(
        [entry2, entry3, entry1], // Out of order intentionally
        1000.0,
      );

      // Should be sorted by date: entry1, entry2, entry3
      expect(result[0]['entry'], entry1);
      expect(result[0]['runningBalance'], 2000.0); // 1000 + 1000

      expect(result[1]['entry'], entry2);
      expect(result[1]['runningBalance'], 1800.0); // 2000 - 200

      expect(result[2]['entry'], entry3);
      expect(result[2]['runningBalance'], 2300.0); // 1800 + 500
    });
  });
}
