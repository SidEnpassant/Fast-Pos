import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';

/// Pure validation before applying voice-parsed lines to a bill draft.
abstract final class VoiceCommandValidator {
  static String? validate(VoiceBillCommand command) {
    if (command.lines.isEmpty) {
      return 'No bill lines recognized. Try again or add items manually.';
    }
    for (final line in command.lines) {
      if (line.productName.trim().isEmpty) {
        return 'A line has an empty product name.';
      }
      if (line.quantity < 1 || line.quantity > 9999) {
        return 'Invalid quantity for ${line.productName}.';
      }
    }
    return null;
  }
}
