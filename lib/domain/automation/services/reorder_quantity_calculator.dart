abstract final class ReorderQuantityCalculator {
  static int suggested({
    required double velocityEma,
    required int stockQuantity,
    int leadDays = 7,
  }) {
    if (velocityEma <= 0) return 0;
    final need = (velocityEma * leadDays).ceil();
    return (need - stockQuantity).clamp(0, 9999);
  }
}
