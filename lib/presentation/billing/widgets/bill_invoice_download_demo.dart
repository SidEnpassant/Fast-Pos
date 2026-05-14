import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/billing/download_remote_pdf_to_device_use_case.dart';

/// Demo / utility: download a remote PDF to device storage (keeps legacy behavior).
abstract final class BillInvoiceDownloadDemo {
  BillInvoiceDownloadDemo._();

  static const samplePdfUrl =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  static Future<bool> verifyFileExists(String filePath) {
    return File(filePath).exists();
  }

  /// Same sample flow as the original [downloadInvoice] on the bill screen.
  static Future<void> runSampleDownload(BuildContext context) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final download = context.read<DownloadRemotePdfToDeviceUseCase>();
      final filePath = await download(samplePdfUrl);

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
