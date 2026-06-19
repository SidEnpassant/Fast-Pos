import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/credit_note.dart';
import 'package:inventopos/domain/returns/return_policy.dart';

void main() {
  group('ReturnPolicy', () {
    final originalBill = Bill(
      id: 'b1',
      userId: 'u1',
      displayBillNumber: 'B-001',
      customerName: 'Test Customer',
      customerPhone: '1234567890',
      totalAmount: 1000,
      paidAmount: 1000,
      paymentMethod: 'cash',
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      lineItems: const [
        BillLineItem(productName: 'Item A', quantity: 2, totalPrice: 500, gstPercent: 10, taxAmount: 50),
        BillLineItem(productName: 'Item B', quantity: 5, totalPrice: 500, gstPercent: 5, taxAmount: 25),
      ],
    );

    test('validateReturn returns success for valid return lines', () {
      final returnLines = [
        const CreditNoteLine(productId: 'p1', productName: 'Item A', quantity: 1, unitPrice: 250, lineTotal: 250, gstAmount: 25),
        const CreditNoteLine(productId: 'p2', productName: 'Item B', quantity: 5, unitPrice: 100, lineTotal: 500, gstAmount: 25),
      ];

      final validation = ReturnPolicy.validateReturn(originalBill, returnLines);
      expect(validation.isValid, true);
      expect(validation.errors, isEmpty);
    });

    test('validateReturn returns failure if return item not in original bill', () {
      final returnLines = [
        const CreditNoteLine(productId: 'p3', productName: 'Item C', quantity: 1, unitPrice: 100, lineTotal: 100, gstAmount: 10),
      ];

      final validation = ReturnPolicy.validateReturn(originalBill, returnLines);
      expect(validation.isValid, false);
      expect(validation.errors.first, contains('not found in the original bill'));
    });

    test('validateReturn returns failure if return quantity exceeds purchased', () {
      final returnLines = [
        const CreditNoteLine(productId: 'p1', productName: 'Item A', quantity: 3, unitPrice: 250, lineTotal: 750, gstAmount: 75),
      ];

      final validation = ReturnPolicy.validateReturn(originalBill, returnLines);
      expect(validation.isValid, false);
      expect(validation.errors.first, contains('Cannot return more than purchased'));
    });

    test('computeRefund calculates total refund amount correctly', () {
      final returnLines = [
        const CreditNoteLine(productId: 'p1', productName: 'Item A', quantity: 1, unitPrice: 250, lineTotal: 250, gstAmount: 25),
        const CreditNoteLine(productId: 'p2', productName: 'Item B', quantity: 2, unitPrice: 100, lineTotal: 200, gstAmount: 10),
      ];

      final refundWithGst = ReturnPolicy.computeRefund(returnLines, includeGst: true);
      expect(refundWithGst, 485.0); // 250 + 25 + 200 + 10

      final refundWithoutGst = ReturnPolicy.computeRefund(returnLines, includeGst: false);
      expect(refundWithoutGst, 450.0); // 250 + 200
    });
  });
}
