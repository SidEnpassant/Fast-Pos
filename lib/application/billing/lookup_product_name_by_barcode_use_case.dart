import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LookupProductNameByBarcodeUseCase {
  LookupProductNameByBarcodeUseCase(
    this._products,
    this._fallback,
  );

  final ProductRepository _products;
  final BarcodeProductLookupRepository _fallback;

  Future<String?> call(String? barcode) async {
    if (barcode == null || barcode.isEmpty) return null;
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final product = await _products.findByBarcode(uid, barcode);
        if (product != null) return product.name;
      }
    } catch (_) {}
    return _fallback.lookupProductName(barcode);
  }
}
