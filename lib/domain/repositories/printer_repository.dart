import 'package:inventopos/domain/entities/receipt_payload.dart';

abstract class PrinterRepository {
  Stream<List<Map<String, dynamic>>> scanDevices();

  Future<void> saveDefaultPrinter({
    required String userId,
    required String macAddress,
    required String name,
    required int paperWidthMm,
  });

  Future<Map<String, dynamic>?> getDefaultPrinter(String userId);

  Future<void> printReceipt(ReceiptPayload payload);
}
