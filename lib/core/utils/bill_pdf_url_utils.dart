/// Helpers for versioned public PDF URLs (cache busting on Supabase CDN).
abstract final class BillPdfUrlUtils {
  static String withCacheBuster(String publicUrl, DateTime updatedAt) {
    final base = stripCacheBuster(publicUrl);
    return '$base?v=${updatedAt.millisecondsSinceEpoch}';
  }

  static String stripCacheBuster(String url) {
    final q = url.indexOf('?');
    if (q < 0) return url;
    return url.substring(0, q);
  }

  static String? storagePathFromPublicUrl(String url, {String bucket = 'bill_pdfs'}) {
    final clean = stripCacheBuster(url);
    final marker = '/$bucket/';
    final idx = clean.indexOf(marker);
    if (idx < 0) return null;
    return clean.substring(idx + marker.length);
  }
}
