import 'package:flutter/material.dart';
import 'package:inventopos/application/billing/lookup_product_name_by_barcode_use_case.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> showBarcodeProductNameBottomSheet(
  BuildContext context, {
  required MobileScannerController scannerController,
  required LookupProductNameByBarcodeUseCase lookup,
}) async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }

  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.7,
      child: Column(
        children: [
          AppBar(
            title: const Text('Scan Barcode'),
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
                  controller: scannerController,
                  onDetect: (BarcodeCapture capture) async {
                    final barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;
                    final barcode = barcodes.first.rawValue;
                    try {
                      final name = await lookup(barcode);
                      if (name != null && sheetContext.mounted) {
                        Navigator.pop(sheetContext, name);
                      } else {
                        debugPrint('Product not found or error in response.');
                      }
                    } catch (e) {
                      debugPrint('Error looking up product: $e');
                    }
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 300),
                          child: Text(
                            'Place barcode inside the box',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
