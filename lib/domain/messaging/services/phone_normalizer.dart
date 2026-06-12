/// Normalizes Indian phone numbers for wa.me / sms: links.
abstract final class PhoneNormalizer {
  static String? digitsOnly(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return null;
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  /// wa.me expects country code without + (91 for India).
  static String? forWhatsApp(String? raw, {String countryCode = '91'}) {
    final d = digitsOnly(raw);
    if (d == null) return null;
    return '$countryCode$d';
  }

  static String? forSms(String? raw) => digitsOnly(raw);
}
