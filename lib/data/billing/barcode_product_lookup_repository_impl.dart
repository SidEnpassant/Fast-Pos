import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inventopos/domain/repositories/barcode_product_lookup_repository.dart';

/// HTTP lookup against Barcode Lookup API (configure API key for production).
class BarcodeProductLookupRepositoryImpl
    implements BarcodeProductLookupRepository {
  BarcodeProductLookupRepositoryImpl({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _baseUrl = 'https://api.barcodelookup.com/v3/products';

  @override
  Future<String?> lookupProductName(String? barcode) async {
    if (barcode == null || barcode.isEmpty) {
      return null;
    }
    try {
      const apiKey = 'YOUR_API_KEY'; // Replace with your Barcode Lookup API key
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: <String, String>{
          'barcode': barcode,
          'key': apiKey,
        },
      );
      final response = await _http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final data = json.decode(response.body) as Map<String, dynamic>?;
      final products = data?['products'];
      if (products is! List || products.isEmpty) {
        return null;
      }
      final first = products.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }
      final name = first['product_name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
