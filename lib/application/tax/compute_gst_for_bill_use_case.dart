import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/tax/gst_config.dart';

class ComputeGstForBillUseCase {
  const ComputeGstForBillUseCase();

  GstInvoiceSummary call({
    required List<BillDraftLine> lines,
    required GstConfig config,
    required bool isInterState,
  }) {
    if (!config.isComposition &&
        config.businessGstin != null &&
        config.businessGstin!.isNotEmpty) {
      final List<GstLineResult> results = [];
      for (final line in lines) {
        final gstPercent = line.gstPercent ?? config.defaultGstSlab;
        results.add(
          GstCalculator.computeLine(
            price: line.price,
            qty: line.quantity,
            gstPercent: gstPercent,
            isInterState: isInterState,
          ),
        );
      }
      return GstCalculator.computeInvoiceSummary(results);
    } else {
      // Return zero tax summary for composition or non-GST registered
      return GstInvoiceSummary(
        totalTaxableValue:
            lines.fold(0, (sum, item) => sum + (item.price * item.quantity)),
        totalCgst: 0,
        totalSgst: 0,
        totalIgst: 0,
        totalTaxAmount: 0,
        lineResults: lines
            .map((e) => const GstLineResult(
                  taxableValue: 0,
                  cgstRate: 0,
                  cgstAmount: 0,
                  sgstRate: 0,
                  sgstAmount: 0,
                  igstRate: 0,
                  igstAmount: 0,
                ))
            .toList(),
      );
    }
  }
}
