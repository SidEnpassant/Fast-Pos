import 'dart:io';

import 'package:inventopos/core/utils/bill_pdf_url_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Downloads a bill PDF — prefers on-device copy, then Supabase storage.
class DownloadBillPdfUseCase {
  DownloadBillPdfUseCase({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bucket = 'bill_pdfs';

  Future<String?> call({
    required String billId,
    String? pdfUrl,
  }) async {
    final localPath = await localDocumentPath(billId);
    if (localPath != null && await File(localPath).exists()) {
      return localPath;
    }

    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final bytes =
            await _client.storage.from(_bucket).download('$uid/$billId.pdf');
        return _writeTempFile(billId, bytes);
      } catch (_) {}
    }

    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      final storagePath = BillPdfUrlUtils.storagePathFromPublicUrl(pdfUrl);
      if (storagePath != null) {
        try {
          final bytes =
              await _client.storage.from(_bucket).download(storagePath);
          return _writeTempFile(billId, bytes);
        } catch (_) {}
      }

      try {
        return await _downloadHttp(billId, pdfUrl);
      } catch (_) {}
    }

    return null;
  }

  static Future<String?> localDocumentPath(String billId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/bill_$billId.pdf';
  }

  Future<String> _writeTempFile(String billId, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/bill_$billId.pdf';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<String?> _downloadHttp(String billId, String pdfUrl) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(BillPdfUrlUtils.stripCacheBuster(pdfUrl));
      final busted = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final request = await client.getUrl(busted);
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = await response.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );
      if (bytes.isEmpty) return null;
      return _writeTempFile(billId, bytes);
    } finally {
      client.close();
    }
  }
}
