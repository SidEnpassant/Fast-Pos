import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/tax/gst_config.dart';

void main() {
  group('GstCalculator', () {
    test('computes line correctly for intra-state sales', () {
      final result = GstCalculator.computeLine(
        price: 1000,
        qty: 2,
        gstPercent: 18,
        isInterState: false,
      );

      expect(result.taxableValue, 2000.0);
      expect(result.cgstRate, 9.0);
      expect(result.sgstRate, 9.0);
      expect(result.igstRate, 0.0);
      expect(result.cgstAmount, 180.0);
      expect(result.sgstAmount, 180.0);
      expect(result.igstAmount, 0.0);
      expect(result.totalTaxAmount, 360.0);
    });

    test('computes line correctly for inter-state sales', () {
      final result = GstCalculator.computeLine(
        price: 500,
        qty: 1,
        gstPercent: 5,
        isInterState: true,
      );

      expect(result.taxableValue, 500.0);
      expect(result.cgstRate, 0.0);
      expect(result.sgstRate, 0.0);
      expect(result.igstRate, 5.0);
      expect(result.cgstAmount, 0.0);
      expect(result.sgstAmount, 0.0);
      expect(result.igstAmount, 25.0);
      expect(result.totalTaxAmount, 25.0);
    });

    test('computes invoice summary correctly', () {
      final line1 = GstCalculator.computeLine(
        price: 1000,
        qty: 1,
        gstPercent: 18,
        isInterState: false,
      );
      final line2 = GstCalculator.computeLine(
        price: 2000,
        qty: 1,
        gstPercent: 12,
        isInterState: false,
      );

      final summary = GstCalculator.computeInvoiceSummary([line1, line2]);

      expect(summary.totalTaxableValue, 3000.0);
      expect(summary.totalCgst, 210.0); // 90 + 120
      expect(summary.totalSgst, 210.0); // 90 + 120
      expect(summary.totalIgst, 0.0);
      expect(summary.totalTaxAmount, 420.0);
    });
  });
}
