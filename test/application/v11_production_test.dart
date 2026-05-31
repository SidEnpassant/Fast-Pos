import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/billing/validate_bill_line_quantity.dart';
import 'package:inventopos/application/customers/phone_normalizer.dart';
import 'package:inventopos/domain/billing/bill_draft_line.dart';

void main() {
  group('ValidateBillLineQuantity', () {
    test('rejects quantity below 1', () {
      final r = ValidateBillLineQuantity.validate(
        quantity: 0,
        availableStock: 10,
        productId: 'p1',
        existingLines: const [],
      );
      expect(r.isValid, isFalse);
    });

    test('rejects over stock including draft lines', () {
      const existing = [
        BillDraftLine(
          name: 'A',
          price: 1,
          quantity: 3,
          productId: 'p1',
        ),
      ];
      final r = ValidateBillLineQuantity.validate(
        quantity: 8,
        availableStock: 10,
        productId: 'p1',
        existingLines: existing,
      );
      expect(r.isValid, isFalse);
      expect(r.maxAllowed, 7);
    });

    test('allows manual line without product id', () {
      final r = ValidateBillLineQuantity.validate(
        quantity: 99,
        existingLines: const [],
      );
      expect(r.isValid, isTrue);
    });
  });

  group('PhoneNormalizer', () {
    test('normalizes to last 10 digits', () {
      expect(PhoneNormalizer.normalize('+91 98765 43210'), '9876543210');
      expect(PhoneNormalizer.normalize('9876543210'), '9876543210');
    });
  });
}
