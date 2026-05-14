import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Demo / utility: download a remote PDF to device storage (keeps legacy behavior).
abstract final class BillInvoiceDownloadDemo {
  BillInvoiceDownloadDemo._();

  static Future<String?> downloadPdfFromUrl(String pdfUrl) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 30) {
          directory = await getExternalStorageDirectory();
        } else {
          directory = Directory('/storage/emulated/0/Download');
        }

        if (directory != null && !(await directory.exists())) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filename = 'invoice_$timestamp.pdf';
      final saveFilePath = '${directory.path}/$filename';

      final response = await http.get(Uri.parse(pdfUrl)).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Download timeout');
        },
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/pdf') ==
                true ||
            response.bodyBytes.isNotEmpty) {
          final file = File(saveFilePath);
          await file.writeAsBytes(response.bodyBytes);
          if (await file.exists()) {
            return saveFilePath;
          }
          throw Exception('File was not created');
        }
        throw Exception('Invalid PDF data received');
      }
      throw Exception('Failed to download PDF: ${response.statusCode}');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> verifyFileExists(String filePath) async {
    return File(filePath).exists();
  }

  /// Same sample flow as the original [downloadInvoice] on the bill screen.
  static Future<void> runSampleDownload(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final filePath = await downloadPdfFromUrl(
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      );

      if (context.mounted) Navigator.pop(context);

      if (filePath != null && await verifyFileExists(filePath)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded successfully to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download PDF. Please check the logs.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
