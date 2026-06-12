import 'package:inventopos/domain/automation/entities/repeat_order_template.dart';
import 'package:inventopos/domain/entities/bill.dart';

class RepeatOrderAnalyzer {
  static RepeatOrderTemplate analyze(String customerId, List<Bill> history) {
    final customerBills = history.where((b) => b.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (customerBills.isEmpty) {
      return RepeatOrderTemplate(customerId: customerId, items: const []);
    }

    final Map<String, List<int>> productQtys = {};
    final Map<String, double> lastPrices = {};

    for (final bill in customerBills.take(5)) {
      for (final item in bill.lineItems) {
        productQtys.putIfAbsent(item.productName, () => []).add(item.quantity);
        lastPrices.putIfAbsent(item.productName, () => item.totalPrice / item.quantity);
      }
    }

    final suggestions = productQtys.entries.map((e) {
      final name = e.key;
      final qtys = e.value;
      final avgQty = (qtys.reduce((a, b) => a + b) / qtys.length).round();
      return RepeatOrderItem(
        productName: name,
        lastPrice: lastPrices[name] ?? 0,
        avgQuantity: avgQty > 0 ? avgQty : 1,
      );
    }).toList();

    // Sort by frequency
    suggestions.sort((a, b) {
      final freqA = productQtys[a.productName]?.length ?? 0;
      final freqB = productQtys[b.productName]?.length ?? 0;
      return freqB.compareTo(freqA);
    });

    return RepeatOrderTemplate(
      customerId: customerId,
      items: suggestions.take(5).toList(),
    );
  }
}
