import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_bloc.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_state.dart';

void showMessagePreviewSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<MessagingAutomationBloc>(),
      child: const _MessagePreviewBody(),
    ),
  );
}

class _MessagePreviewBody extends StatefulWidget {
  const _MessagePreviewBody();

  @override
  State<_MessagePreviewBody> createState() => _MessagePreviewBodyState();
}

class _MessagePreviewBodyState extends State<_MessagePreviewBody> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final body = context.read<MessagingAutomationBloc>().state.preview?.body ?? '';
    _controller = TextEditingController(text: body);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagingAutomationBloc, MessagingAutomationState>(
      listener: (context, state) {
        if (state.error == null && !state.launching && state.preview == null) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final preview = state.preview;
        if (preview == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review message',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'You tap Send in WhatsApp or SMS — nothing is sent automatically.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 5,
                onChanged: (v) => context
                    .read<MessagingAutomationBloc>()
                    .add(MessagingBodyEdited(v)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('WhatsApp'),
                    selected: preview.channel == MessageChannel.whatsapp,
                    onSelected: (_) => context.read<MessagingAutomationBloc>().add(
                          const MessagingChannelChanged(MessageChannel.whatsapp),
                        ),
                  ),
                  ChoiceChip(
                    label: const Text('SMS'),
                    selected: preview.channel == MessageChannel.sms,
                    onSelected: (_) => context.read<MessagingAutomationBloc>().add(
                          const MessagingChannelChanged(MessageChannel.sms),
                        ),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.launching
                    ? null
                    : () => context
                        .read<MessagingAutomationBloc>()
                        .add(const MessagingLaunchRequested()),
                child: state.launching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Open in messaging app'),
              ),
            ],
          ),
        );
      },
    );
  }
}
