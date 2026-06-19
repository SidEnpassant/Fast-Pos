import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/widgets/message_preview_sheet.dart';
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
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12), // AppRadii.md equivalent
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              _iconFor(message.channel),
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            message.recipientName ?? message.phone,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            message.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: () => _openPreview(context),
        ),
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
