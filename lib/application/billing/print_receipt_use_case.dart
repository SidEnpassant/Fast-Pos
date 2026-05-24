import 'package:inventopos/domain/entities/receipt_payload.dart';
import 'package:inventopos/domain/repositories/printer_repository.dart';

class PrintReceiptUseCase {
  PrintReceiptUseCase(this._printer);

  final PrinterRepository _printer;

  Future<void> call(ReceiptPayload payload) => _printer.printReceipt(payload);
}
