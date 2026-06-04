import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/entities/product.dart';

/// Rule-based fallback when cloud suggestions are unavailable.
abstract final class SuggestionRanker {
  static List<BillingSuggestion> fromProducts({
    required String prefix,
    required List<Product> products,
    int limit = 5,
  }) {
    final q = prefix.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final scored = <({Product p, int score})>[];
    for (final p in products) {
      if (!p.isActive) continue;
      final name = p.name.toLowerCase();
      int score = 0;
      if (name.startsWith(q)) {
        score = 100;
      } else if (name.contains(q)) {
        score = 50;
      } else {
        continue;
      }
      if (p.isLowStock) score -= 5;
      scored.add((p: p, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(limit)
        .map(
          (e) => BillingSuggestion(
            productId: e.p.id,
            productName: e.p.name,
            reason: 'Matches "$prefix"',
          ),
        )
        .toList();
  }
}
