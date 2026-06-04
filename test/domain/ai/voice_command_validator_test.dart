import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/ai/services/voice_command_validator.dart';

void main() {
  test('rejects empty lines', () {
    expect(
      VoiceCommandValidator.validate(const VoiceBillCommand()),
      isNotNull,
    );
  });

  test('accepts valid command', () {
    expect(
      VoiceCommandValidator.validate(
        const VoiceBillCommand(
          lines: [VoiceBillLine(productName: 'Chai', quantity: 2)],
        ),
      ),
      isNull,
    );
  });
}
