import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_gateway_port.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/domain/ai/services/suggestion_ranker.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';
import 'package:inventopos/domain/entities/product.dart';

class GetBillingSuggestionsUseCase {
  GetBillingSuggestionsUseCase(this._gateway, this._preferences);

  final AiGatewayPort _gateway;
  final AiPreferencesPort _preferences;

  Future<List<BillingSuggestion>> call({
    required String userId,
    required String prefix,
    required List<Product> products,
    required List<String> basketProductIds,
    bool isOnline = true,
  }) async {
    final prefs = await _preferences.fetch(userId);
    if (!AutomationPolicy.canInvokeCloudAi(prefs) || !isOnline) {
      return SuggestionRanker.fromProducts(prefix: prefix, products: products);
    }
    final catalog = products
        .where((p) => p.isActive)
        .take(200)
        .map((p) => {'id': p.id, 'name': p.name})
        .toList();
    final result = await _gateway.suggestProducts(
      prefix: prefix,
      basketProductIds: basketProductIds,
      catalog: catalog,
    );
    return switch (result) {
      AiSuccess(:final value) => _enrich(value, products),
      AiError() => SuggestionRanker.fromProducts(prefix: prefix, products: products),
    };
  }

  List<BillingSuggestion> _enrich(
    List<BillingSuggestion> raw,
    List<Product> products,
  ) {
    final byId = {for (final p in products) p.id: p};
    return raw
        .map(
          (s) => BillingSuggestion(
            productId: s.productId,
            reason: s.reason,
            productName: byId[s.productId]?.name ?? s.productName,
          ),
        )
        .toList();
  }
}
