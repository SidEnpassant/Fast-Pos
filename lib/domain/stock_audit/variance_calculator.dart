import '../entities/stock_audit.dart';

class VarianceResult {
  final double variance;
  final double variancePercent;

  const VarianceResult(this.variance, this.variancePercent);
}

class AuditSummaryResult {
  final double totalVariance;
  final double positiveVariance;
  final double negativeVariance;

  const AuditSummaryResult({
    required this.totalVariance,
    required this.positiveVariance,
    required this.negativeVariance,
  });
}

class VarianceCalculator {
  static VarianceResult computeVariance(double systemQty, double physicalQty) {
    final variance = physicalQty - systemQty;
    final variancePercent = systemQty == 0 ? 0.0 : (variance / systemQty) * 100;
    return VarianceResult(variance, variancePercent);
  }

  static AuditSummaryResult computeAuditSummary(List<StockAuditLine> lines) {
    double totalVariance = 0;
    double positiveVariance = 0;
    double negativeVariance = 0;

    for (final line in lines) {
      totalVariance += line.variance;
      if (line.variance > 0) {
        positiveVariance += line.variance;
      } else if (line.variance < 0) {
        negativeVariance += line.variance.abs();
      }
    }

    return AuditSummaryResult(
      totalVariance: totalVariance,
      positiveVariance: positiveVariance,
      negativeVariance: negativeVariance,
    );
  }
}
