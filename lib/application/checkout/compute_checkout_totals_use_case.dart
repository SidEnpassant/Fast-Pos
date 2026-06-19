import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/checkout/discount_strategy.dart';

class ComputeCheckoutTotalsUseCase {
  DiscountedCart call({
    required List<BillDraftLine> lines,
    required List<DiscountStrategy> strategies,
    DiscountContext context = const DiscountContext(),
  }) {
    final subtotal = lines.fold<double>(0, (s, l) => s + l.price * l.quantity);
    var cart = DiscountedCart(
      lines: lines,
      subtotal: subtotal,
      discountTotal: 0,
      breakdown: const [],
    );
    for (final strategy in strategies) {
      cart = strategy.apply(cart, context);
    }
    return cart;
  }
}
