import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 bill integrity hashing (feature 15).
abstract final class BillAuditService {
  static String hashPayload(Map<String, dynamic> payload) {
    final canonical = _canonicalJson(payload);
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static bool verify(Map<String, dynamic> payload, String expectedHash) {
    return hashPayload(payload) == expectedHash;
  }

  static String _canonicalJson(Map<String, dynamic> map) {
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return jsonEncode(sorted);
  }
}
