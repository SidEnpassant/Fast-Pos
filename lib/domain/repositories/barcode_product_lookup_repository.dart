/// Resolves a human-readable product name from a barcode value (remote lookup).
abstract class BarcodeProductLookupRepository {
  Future<String?> lookupProductName(String? barcode);
}
