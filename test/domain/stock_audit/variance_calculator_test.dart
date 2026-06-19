import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/domain/stock_audit/variance_calculator.dart';

void main() {
  group('VarianceCalculator', () {
    test('computeVariance calculates correct values', () {
      final result1 = VarianceCalculator.computeVariance(10.0, 12.0);
      expect(result1.variance, 2.0);
      expect(result1.variancePercent, 20.0);

      final result2 = VarianceCalculator.computeVariance(10.0, 8.0);
      expect(result2.variance, -2.0);
      expect(result2.variancePercent, -20.0);

      final result3 = VarianceCalculator.computeVariance(0.0, 5.0);
      expect(result3.variance, 5.0);
      expect(result3.variancePercent, 0.0); // Should handle division by zero
    });

    test('computeAuditSummary aggregates variances correctly', () {
      final lines = [
        const StockAuditLine(
          id: '1',
          auditId: 'a1',
          productId: 'p1',
          productName: 'Item 1',
          systemQty: 10,
          physicalQty: 12,
          variance: 2,
        ),
        const StockAuditLine(
          id: '2',
          auditId: 'a1',
          productId: 'p2',
          productName: 'Item 2',
          systemQty: 5,
          physicalQty: 2,
          variance: -3,
        ),
        const StockAuditLine(
          id: '3',
          auditId: 'a1',
          productId: 'p3',
          productName: 'Item 3',
          systemQty: 100,
          physicalQty: 100,
          variance: 0,
        ),
      ];

      final summary = VarianceCalculator.computeAuditSummary(lines);
      
      expect(summary.totalVariance, -1.0); // 2 + (-3) + 0
      expect(summary.positiveVariance, 2.0);
      expect(summary.negativeVariance, 3.0); // Absolute value expected
    });
  });
}
