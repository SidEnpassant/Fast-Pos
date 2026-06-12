import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/messaging/entities/message_template_id.dart';
import 'package:inventopos/domain/messaging/services/message_template_renderer.dart';
import 'package:inventopos/domain/messaging/services/phone_normalizer.dart';

void main() {
  test('MessageTemplateRenderer replaces placeholders', () {
    final text = MessageTemplateRenderer.render(
      MessageTemplateId.partialReminder,
      locale: 'en',
      vars: {
        'customerName': 'Ravi',
        'shopName': 'Fast Shop',
        'amountDue': '500',
        'billNo': '42',
        'upiLine': '',
      },
    );
    expect(text, contains('Ravi'));
    expect(text, contains('500'));
  });

  test('PhoneNormalizer formats WhatsApp number', () {
    expect(PhoneNormalizer.forWhatsApp('9876543210'), '919876543210');
    expect(PhoneNormalizer.forWhatsApp('invalid'), isNull);
  });
}
