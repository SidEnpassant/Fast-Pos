import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';
import 'package:inventopos/domain/messaging/repositories/outbound_messaging_port.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/message_template_id.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/domain/messaging/services/message_template_renderer.dart';

class BuildPartialPaymentMessageUseCase {
  OutboundMessage call({
    required Bill bill,
    required String shopName,
    required AiPreferences prefs,
    String? upiId,
  }) {
    final due = bill.totalAmount - bill.paidAmount;
    final upi = upiId ?? prefs.merchantUpiId;
    final upiLine = upi != null && upi.isNotEmpty ? ' Pay via UPI: $upi.' : '';
    final body = MessageTemplateRenderer.render(
      MessageTemplateId.partialReminder,
      locale: prefs.language,
      vars: {
        'customerName': bill.customerName,
        'shopName': shopName,
        'amountDue': due.toStringAsFixed(0),
        'billNo': bill.displayBillNumber ?? bill.id.substring(0, 8),
        'upiLine': upiLine,
      },
    );
    return OutboundMessage(
      channel: _channel(prefs),
      phone: bill.customerPhone,
      body: body,
      templateId: MessageTemplateId.partialReminder,
      recipientName: bill.customerName,
    );
  }

  MessageChannel _channel(AiPreferences prefs) =>
      prefs.defaultMessageChannel == 'sms'
          ? MessageChannel.sms
          : MessageChannel.whatsapp;
}

class BuildPaymentThankYouMessageUseCase {
  OutboundMessage call({
    required Bill bill,
    required String shopName,
    required AiPreferences prefs,
  }) {
    final body = MessageTemplateRenderer.render(
      MessageTemplateId.paymentThankYou,
      locale: prefs.language,
      vars: {
        'customerName': bill.customerName,
        'shopName': shopName,
        'total': bill.totalAmount.toStringAsFixed(0),
      },
    );
    return OutboundMessage(
      channel: prefs.defaultMessageChannel == 'sms'
          ? MessageChannel.sms
          : MessageChannel.whatsapp,
      phone: bill.customerPhone,
      body: body,
      templateId: MessageTemplateId.paymentThankYou,
    );
  }
}

class BuildReceiptMessageUseCase {
  OutboundMessage call({
    required Bill bill,
    required String shopName,
    required AiPreferences prefs,
  }) {
    final body = MessageTemplateRenderer.render(
      MessageTemplateId.receipt,
      locale: prefs.language,
      vars: {
        'billNo': bill.displayBillNumber ?? bill.id.substring(0, 8),
        'total': bill.totalAmount.toStringAsFixed(0),
        'paid': bill.paidAmount.toStringAsFixed(0),
        'shopName': shopName,
      },
    );
    return OutboundMessage(
      channel: MessageChannel.whatsapp,
      phone: bill.customerPhone,
      body: body,
      templateId: MessageTemplateId.receipt,
    );
  }
}

class BuildEodSummaryMessageUseCase {
  OutboundMessage call({
    required String shopName,
    required AiPreferences prefs,
    required int billCount,
    required double revenue,
    required double collected,
    required double pending,
  }) {
    final body = MessageTemplateRenderer.render(
      MessageTemplateId.eodSummary,
      locale: prefs.language,
      vars: {
        'shopName': shopName,
        'billCount': '$billCount',
        'revenue': revenue.toStringAsFixed(0),
        'collected': collected.toStringAsFixed(0),
        'pending': pending.toStringAsFixed(0),
      },
    );
    return OutboundMessage(
      channel: MessageChannel.whatsapp,
      phone: prefs.ownerWhatsAppPhone ?? '',
      body: body,
      templateId: MessageTemplateId.eodSummary,
    );
  }
}

class LaunchOutboundMessageUseCase {
  LaunchOutboundMessageUseCase(this._messaging);

  final OutboundMessagingPort _messaging;

  Future<String?> call({
    required OutboundMessage message,
    required AiPreferences prefs,
  }) async {
    if (!AutomationPolicy.canLaunchOutboundMessage(prefs)) {
      return 'Automations are disabled';
    }
    final result = await _messaging.launch(message);
    return result.failure?.message;
  }
}
