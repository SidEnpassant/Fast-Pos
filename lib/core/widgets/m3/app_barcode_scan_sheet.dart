import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full-height barcode scanner; returns scanned string or null.
Future<String?> showAppBarcodeScanSheet(
  BuildContext context, {
  MobileScannerController? controller,
  String title = 'Scan barcode',
}) async {
  final status = await Permission.camera.request();
  if (status.isDenied) return null;
  if (!context.mounted) return null;

  final scanController = controller ?? MobileScannerController();
  var locked = false;

  final result = await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        child: Column(
          children: [
            AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: scanController,
                    onDetect: (capture) async {
                      if (locked) return;
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      final code = barcodes.first.rawValue;
                      if (code == null || code.isEmpty) return;
                      locked = true;
                      await HapticFeedback.mediumImpact();
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext, code);
                      }
                    },
                  ),
                  Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Positioned(
                    bottom: 24,
                    child: Text(
                      'Align barcode inside the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  if (controller == null) {
    await scanController.dispose();
  }
  return result;
}
