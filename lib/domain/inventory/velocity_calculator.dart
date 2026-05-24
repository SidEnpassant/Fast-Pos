/// EMA-based sales velocity for predictive reorder (feature 19).
abstract final class VelocityCalculator {
  static const defaultAlpha = 0.25;
  static const defaultReorderDaysThreshold = 7.0;

  static double nextVelocity({
    required double previousVelocity,
    required double qtySoldToday,
    double alpha = defaultAlpha,
  }) {
    return (qtySoldToday * alpha) + (previousVelocity * (1 - alpha));
  }

  static double daysRemaining({
    required int stockQuantity,
    required double velocity,
  }) {
    if (velocity <= 0) return double.infinity;
    return stockQuantity / velocity;
  }

  static bool shouldReorder({
    required int stockQuantity,
    required double velocity,
    double thresholdDays = defaultReorderDaysThreshold,
  }) {
    return daysRemaining(
          stockQuantity: stockQuantity,
          velocity: velocity,
        ) <
        thresholdDays;
  }
}
