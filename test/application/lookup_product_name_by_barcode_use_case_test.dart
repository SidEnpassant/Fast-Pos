import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class _FakeBarcodeLookup implements BarcodeProductLookupRepository {
  @override
  Future<String?> lookupProductName(String? barcode) async {
    if (barcode == null || barcode.isEmpty) return null;
    return 'Product-$barcode';
  }
}

class _FakeProducts implements ProductRepository {
  @override
  Future<Product?> findByBarcode(String userId, String barcode) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('LookupProductNameByBarcodeUseCase uses fallback when local miss',
      () async {
    final uc = LookupProductNameByBarcodeUseCase(
      _FakeProducts(),
      _FakeBarcodeLookup(),
    );
    expect(await uc('123'), 'Product-123');
    expect(await uc(null), isNull);
  });
}
