import 'package:inventopos/domain/messaging/entities/message_template_id.dart';

/// Pure template rendering — no I/O.
abstract final class MessageTemplateRenderer {
  static String render(
    MessageTemplateId id, {
    required Map<String, String> vars,
    String locale = 'en',
  }) {
    final template = _template(id, locale);
    var out = template;
    for (final e in vars.entries) {
      out = out.replaceAll('{{${e.key}}}', e.value);
    }
    return out;
  }

  static String _template(MessageTemplateId id, String locale) {
    final hi = locale == 'hi';
    return switch (id) {
      MessageTemplateId.partialReminder => hi
          ? 'Namaste {{customerName}}, {{shopName}} se ₹{{amountDue}} baaki hai (Bill #{{billNo}}). Kripya jald clear karein.{{upiLine}} Dhanyavaad.'
          : 'Hi {{customerName}}, ₹{{amountDue}} is pending at {{shopName}} (Bill #{{billNo}}). Please clear at your earliest.{{upiLine}} Thank you.',
      MessageTemplateId.paymentThankYou => hi
          ? 'Dhanyavaad {{customerName}}! ₹{{total}} ka payment receive ho gaya. — {{shopName}}'
          : 'Thank you {{customerName}}! We received ₹{{total}}. — {{shopName}}',
      MessageTemplateId.receipt => hi
          ? 'Receipt {{billNo}}: ₹{{total}} (Paid ₹{{paid}}) — {{shopName}}'
          : 'Receipt {{billNo}}: ₹{{total}} (Paid ₹{{paid}}) — {{shopName}}',
      MessageTemplateId.creditWarning => hi
          ? '{{customerName}} ji, aapka outstanding ₹{{creditTotal}} ho gaya hai. — {{shopName}}'
          : 'Hi {{customerName}}, your outstanding balance is ₹{{creditTotal}}. — {{shopName}}',
      MessageTemplateId.supplierReorder => hi
          ? 'Order request:\n{{itemList}}\n— {{shopName}}'
          : 'Reorder request:\n{{itemList}}\n— {{shopName}}',
      MessageTemplateId.eodSummary => hi
          ? 'Aaj ka summary: {{billCount}} bills, ₹{{revenue}} sales, ₹{{collected}} collected, ₹{{pending}} pending. — {{shopName}}'
          : 'Today: {{billCount}} bills, ₹{{revenue}} sales, ₹{{collected}} collected, ₹{{pending}} pending. — {{shopName}}',
      MessageTemplateId.weeklyCollections => hi
          ? 'Is hafte collect karna baaki: ₹{{pendingTotal}} ({{count}} customers). — {{shopName}}'
          : 'Outstanding this week: ₹{{pendingTotal}} from {{count}} customers. — {{shopName}}',
    };
  }
}
