import 'package:inventopos/domain/billing/bill_draft_line.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:inventopos/domain/repositories/sync_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Decrements inventory for catalog lines on a bill (idempotent via stock_applied_at).
class DecrementStockOnBillUseCase {
  DecrementStockOnBillUseCase(
    this._products,
    this._sync, {
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final ProductRepository _products;
  final SyncRepository? _sync;
  final SupabaseClient _client;

  Future<void> call({
    required String billId,
    required List<BillDraftLine> lines,
    required String userId,
  }) async {
    final catalogLines = lines
        .where((l) => l.productId != null && l.productId!.isNotEmpty)
        .toList();
    if (catalogLines.isEmpty) return;

    final payload = catalogLines
        .map((l) => {
              'product_id': l.productId,
              'quantity': l.quantity,
            })
        .toList();

    // Update local Hive immediately so inventory UI reflects the sale.
    for (final line in catalogLines) {
      await _products.decrementStockLocal(
        productId: line.productId!,
        quantity: line.quantity,
      );
    }

    final sync = _sync;
    final online = sync != null ? await sync.isOnline() : true;
    if (online) {
      try {
        await _client.rpc(
          'decrement_stock_for_bill',
          params: {
            'p_bill_id': billId,
            'p_lines': payload,
          },
        );
        await _products.fetchProductsForUser(userId);
      } catch (_) {
        if (sync != null) {
          await sync.enqueue(
            userId: userId,
            operationType: 'decrement_stock',
            payload: {
              'bill_id': billId,
              'lines': payload,
            },
          );
          await sync.processOutbox(userId);
        }
      }
    } else {
      await sync.enqueue(
        userId: userId,
        operationType: 'decrement_stock',
        payload: {
          'bill_id': billId,
          'lines': payload,
        },
      );
    }
  }
}
