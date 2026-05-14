import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';

class _FakeBarcodeLookup implements BarcodeProductLookupRepository {
  @override
  Future<String?> lookupProductName(String? barcode) async {
    if (barcode == null || barcode.isEmpty) return null;
    return 'Product-$barcode';
  }
}

void main() {
  test('LookupProductNameByBarcodeUseCase forwards to repository', () async {
    final uc = LookupProductNameByBarcodeUseCase(_FakeBarcodeLookup());
    expect(await uc('123'), 'Product-123');
    expect(await uc(null), isNull);
    expect(await uc(''), isNull);
  });
}
