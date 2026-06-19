import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';

class ListPendingMessageActionsUseCase {
  ListPendingMessageActionsUseCase({
    required BuildPartialPaymentMessageUseCase buildPartial,
    required BuildEodSummaryMessageUseCase buildEod,
  })  : _buildPartial = buildPartial,
        _buildEod = buildEod;

  final BuildPartialPaymentMessageUseCase _buildPartial;
  final BuildEodSummaryMessageUseCase _buildEod;

  List<OutboundMessage> call({
    required List<Bill> bills,
    required String shopName,
    required AiPreferences prefs,
  }) {
    final List<OutboundMessage> actions = [];

    // 1. Overdue partial bills (> 3 days)
    final overdue = bills.where((b) {
      if (b.paidAmount >= b.totalAmount) return false;
      return b.createdAt
          .isBefore(DateTime.now().subtract(const Duration(days: 3)));
    });

    for (final bill in overdue) {
      actions.add(_buildPartial(
        bill: bill,
        shopName: shopName,
        prefs: prefs,
      ));
    }

    // 2. EOD Summary if it's evening and not sent yet (simplified check)
    if (DateTime.now().hour >= 18 && actions.isEmpty) {
      // Add EOD summary action
      // Note: In a real app we'd check if today's EOD was already shared.
    }

    return actions;
  }
}
