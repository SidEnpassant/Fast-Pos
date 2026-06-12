import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/widgets/message_preview_sheet.dart';

class BillWhatsAppActionButton extends StatelessWidget {
  const BillWhatsAppActionButton({
    super.key,
    required this.bill,
    required this.userId,
  });

  final Bill bill;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'WhatsApp reminder',
      icon: const Icon(Icons.chat),
      onPressed: () => _openPreview(context),
    );
  }

  Future<void> _openPreview(BuildContext context) async {
    final prefs = await context.read<ObserveAiPreferencesUseCase>()(userId).first;
    final profile =
        await context.read<ProfileRepository>().fetchCurrentUserProfileSnapshot();
    final shop = profile?.businessName ?? 'Shop';
    final message = context.read<BuildPartialPaymentMessageUseCase>()(
      bill: bill,
      shopName: shop,
      prefs: prefs,
    );
    if (!context.mounted) return;
    context.read<MessagingAutomationBloc>().add(
          MessagingPreviewRequested(message, prefs),
        );
    showMessagePreviewSheet(context);
  }
}
