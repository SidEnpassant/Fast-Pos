/// Normalizes phone numbers for lookup and unique index (India 10-digit default).
abstract final class PhoneNormalizer {
  static String normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}
