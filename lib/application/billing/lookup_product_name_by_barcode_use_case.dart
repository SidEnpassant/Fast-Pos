import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';

class LookupProductNameByBarcodeUseCase {
  LookupProductNameByBarcodeUseCase(this._lookup);

  final BarcodeProductLookupRepository _lookup;

  Future<String?> call(String? barcode) => _lookup.lookupProductName(barcode);
}
