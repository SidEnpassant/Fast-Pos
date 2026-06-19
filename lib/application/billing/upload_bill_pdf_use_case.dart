import 'dart:async';
import 'dart:io';

import 'package:inventopos/core/utils/bill_pdf_url_utils.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads bill PDF bytes to Supabase storage and updates bill row.
class UploadBillPdfUseCase {
  UploadBillPdfUseCase(
    this._bills, {
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final BillsRepository _bills;
  final SupabaseClient _client;

  static const _bucket = 'bill_pdfs';
  static final _perBillQueue = <String, Future<void>>{};

  Future<String> call({
    required String billId,
    required String localPdfPath,
    String? previousPdfUrl,
  }) async {
    final previous = _perBillQueue[billId] ?? Future<void>.value();
    final completer = Completer<void>();
    _perBillQueue[billId] = completer.future;
    await previous;

    try {
      return await _uploadOnce(
        billId: billId,
        localPdfPath: localPdfPath,
        previousPdfUrl: previousPdfUrl,
      );
    } finally {
      completer.complete();
      if (identical(_perBillQueue[billId], completer.future)) {
        _perBillQueue.remove(billId);
      }
    }
  }

  Future<String> _uploadOnce({
    required String billId,
    required String localPdfPath,
    String? previousPdfUrl,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('User not authenticated');

    await _ensureBillRowExists(billId);

    final storagePath = '$uid/$billId.pdf';
    final bucket = _client.storage.from(_bucket);
    final file = File(localPdfPath);

    await _uploadWithFallback(bucket, storagePath, file);

    final now = DateTime.now();
    final publicUrl = BillPdfUrlUtils.withCacheBuster(
      bucket.getPublicUrl(storagePath),
      now,
    );

    await _bills.updatePdfUrl(
      billId: billId,
      pdfUrl: publicUrl,
      pdfUpdatedAt: now,
    );

    final previousPath = previousPdfUrl != null
        ? BillPdfUrlUtils.storagePathFromPublicUrl(previousPdfUrl)
        : null;
    if (previousPath != null && previousPath != storagePath) {
      try {
        await bucket.remove([previousPath]);
      } catch (_) {}
    }

    return publicUrl;
  }

  Future<void> _uploadWithFallback(
    StorageFileApi bucket,
    String storagePath,
    File file,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await bucket.upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/pdf',
          ),
        );
        return;
      } on StorageException catch (e) {
        if (!_isRetryableStorageError(e) && attempt == 2) rethrow;
      }

      try {
        await bucket.remove([storagePath]);
      } catch (_) {}

      try {
        await bucket.upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            upsert: false,
            contentType: 'application/pdf',
          ),
        );
        return;
      } on StorageException catch (e) {
        if (attempt == 2) rethrow;
        if (!_isRetryableStorageError(e)) rethrow;
      }

      await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    }
  }

  bool _isRetryableStorageError(StorageException e) {
    final msg = e.message.toLowerCase();
    return e.statusCode == '403' ||
        msg.contains('row-level security') ||
        msg.contains('unauthorized') ||
        msg.contains('already exists');
  }

  Future<void> _ensureBillRowExists(String billId) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final row = await _client
          .from('bills')
          .select('id')
          .eq('id', billId)
          .maybeSingle();
      if (row != null) return;
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    throw StateError('Bill row not synced yet; cannot attach PDF');
  }
}
