import 'package:inventopos/domain/billing/bill_draft_line.dart';

class DiscountContext {
  const DiscountContext({this.customerLoyaltyTier});

  final String? customerLoyaltyTier;
}

class DiscountedCart {
  const DiscountedCart({
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.breakdown,
  });

  final List<BillDraftLine> lines;
  final double subtotal;
  final double discountTotal;
  final List<Map<String, dynamic>> breakdown;

  double get total => subtotal - discountTotal;
}

/// Strategy pattern for checkout promotions (feature 23).
abstract interface class DiscountStrategy {
  String get id;
  String get label;
  DiscountedCart apply(DiscountedCart cart, DiscountContext ctx);
}

class PercentageDiscountStrategy implements DiscountStrategy {
  PercentageDiscountStrategy(this.percent);

  final double percent;

  @override
  String get id => 'percentage_$percent';

  @override
  String get label => '${percent.toStringAsFixed(0)}% off';

  @override
  DiscountedCart apply(DiscountedCart cart, DiscountContext ctx) {
    final off = cart.subtotal * (percent / 100);
    return DiscountedCart(
      lines: cart.lines,
      subtotal: cart.subtotal,
      discountTotal: cart.discountTotal + off,
      breakdown: [
        ...cart.breakdown,
        {'type': 'percentage', 'percent': percent, 'amount': off},
      ],
    );
  }
}

class FixedAmountDiscountStrategy implements DiscountStrategy {
  FixedAmountDiscountStrategy(this.amount);

  final double amount;

  @override
  String get id => 'fixed_$amount';

  @override
  String get label => '₹${amount.toStringAsFixed(0)} off';

  @override
  DiscountedCart apply(DiscountedCart cart, DiscountContext ctx) {
    return DiscountedCart(
      lines: cart.lines,
      subtotal: cart.subtotal,
      discountTotal: cart.discountTotal + amount,
      breakdown: [
        ...cart.breakdown,
        {'type': 'fixed', 'amount': amount},
      ],
    );
  }
}

class TieredVolumeDiscountStrategy implements DiscountStrategy {
  TieredVolumeDiscountStrategy({required this.minQty, required this.percent});

  final double minQty;
  final double percent;

  @override
  String get id => 'tier_${minQty}_$percent';

  @override
  String get label => '$minQty+ items: $percent% off';

  @override
  DiscountedCart apply(DiscountedCart cart, DiscountContext ctx) {
    final totalQty = cart.lines.fold<double>(0.0, (s, l) => s + l.quantity);
    if (totalQty < minQty) return cart;
    return PercentageDiscountStrategy(percent).apply(cart, ctx);
  }
}
