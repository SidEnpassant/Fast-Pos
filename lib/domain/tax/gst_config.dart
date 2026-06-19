import 'package:equatable/equatable.dart';

/// Configuration for GST settings at the business level.
class GstConfig extends Equatable {
  final String? businessGstin;
  final String? stateCode;
  final bool isComposition;
  final double defaultGstSlab;

  const GstConfig({
    this.businessGstin,
    this.stateCode,
    this.isComposition = false,
    this.defaultGstSlab = 0.0,
  });

  @override
  List<Object?> get props =>
      [businessGstin, stateCode, isComposition, defaultGstSlab];
}

/// Result of computing GST for a single line item.
class GstLineResult extends Equatable {
  final double taxableValue;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;

  const GstLineResult({
    required this.taxableValue,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
  });

  double get totalTaxAmount => cgstAmount + sgstAmount + igstAmount;

  @override
  List<Object?> get props => [
        taxableValue,
        cgstRate,
        cgstAmount,
        sgstRate,
        sgstAmount,
        igstRate,
        igstAmount,
      ];
}

class GstInvoiceSummary extends Equatable {
  final double totalTaxableValue;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTaxAmount;
  final List<GstLineResult> lineResults;

  const GstInvoiceSummary({
    required this.totalTaxableValue,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTaxAmount,
    required this.lineResults,
  });

  @override
  List<Object?> get props => [
        totalTaxableValue,
        totalCgst,
        totalSgst,
        totalIgst,
        totalTaxAmount,
        lineResults,
      ];
}

/// Pure functions for computing GST.
class GstCalculator {
  /// Computes GST for a single line item.
  /// Note: [price] is assumed to be exclusive of tax.
  static GstLineResult computeLine({
    required double price,
    required double qty,
    required double gstPercent,
    required bool isInterState,
  }) {
    final double taxableValue = price * qty;
    double cgstRate = 0;
    double cgstAmount = 0;
    double sgstRate = 0;
    double sgstAmount = 0;
    double igstRate = 0;
    double igstAmount = 0;

    if (gstPercent > 0) {
      if (isInterState) {
        igstRate = gstPercent;
        igstAmount = taxableValue * (igstRate / 100);
      } else {
        cgstRate = gstPercent / 2;
        sgstRate = gstPercent / 2;
        cgstAmount = taxableValue * (cgstRate / 100);
        sgstAmount = taxableValue * (sgstRate / 100);
      }
    }

    return GstLineResult(
      taxableValue: taxableValue,
      cgstRate: cgstRate,
      cgstAmount: cgstAmount,
      sgstRate: sgstRate,
      sgstAmount: sgstAmount,
      igstRate: igstRate,
      igstAmount: igstAmount,
    );
  }

  /// Computes the invoice-level summary of all taxes.
  static GstInvoiceSummary computeInvoiceSummary(List<GstLineResult> lines) {
    double totalTaxable = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalTax = 0;

    for (final line in lines) {
      totalTaxable += line.taxableValue;
      totalCgst += line.cgstAmount;
      totalSgst += line.sgstAmount;
      totalIgst += line.igstAmount;
      totalTax += line.totalTaxAmount;
    }

    return GstInvoiceSummary(
      totalTaxableValue: totalTaxable,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalTaxAmount: totalTax,
      lineResults: lines,
    );
  }
}
