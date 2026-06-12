import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/widgets/message_preview_sheet.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageActionTile extends StatelessWidget {
  const MessageActionTile({
    super.key,
    required this.message,
    this.trailing,
  });

  final OutboundMessage message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorFor(message.channel).withValues(alpha: 0.1),
          child:
              Icon(_iconFor(message.channel), color: _colorFor(message.channel)),
        ),
        title: Text(message.recipientName ?? message.phone),
        subtitle: Text(
          message.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: () => _openPreview(context),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) async {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    final prefs = await context.read<ObserveAiPreferencesUseCase>()(uid).first;
    if (!context.mounted) return;
    
    context.read<MessagingAutomationBloc>().add(
          MessagingPreviewRequested(message, prefs),
        );
    showMessagePreviewSheet(context);
  }

  IconData _iconFor(MessageChannel channel) {
    return switch (channel) {
      MessageChannel.whatsapp => Icons.chat,
      MessageChannel.sms => Icons.sms,
      MessageChannel.phoneCall => Icons.phone,
      MessageChannel.shareText => Icons.share,
      MessageChannel.shareFile => Icons.file_present,
    };
  }

  Color _colorFor(MessageChannel channel) {
    return switch (channel) {
      MessageChannel.whatsapp => Colors.green,
      MessageChannel.sms => Colors.blue,
      MessageChannel.phoneCall => Colors.orange,
      _ => Colors.grey,
    };
  }
}
