import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:inventopos/domain/repositories/remote_pdf_download_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RemotePdfDownloadRepositoryImpl implements RemotePdfDownloadRepository {
  RemotePdfDownloadRepositoryImpl({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<String?> downloadPdfToDevice(String pdfUrl) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
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

      final response = await _http.get(Uri.parse(pdfUrl)).timeout(
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
}
