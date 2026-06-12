import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/messaging/entities/message_channel.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';

sealed class MessagingAutomationEvent extends Equatable {
  const MessagingAutomationEvent();
  @override
  List<Object?> get props => [];
}

final class MessagingPreviewRequested extends MessagingAutomationEvent {
  const MessagingPreviewRequested(this.message, this.prefs);
  final OutboundMessage message;
  final dynamic prefs;
  @override
  List<Object?> get props => [message];
}

final class MessagingBodyEdited extends MessagingAutomationEvent {
  const MessagingBodyEdited(this.body);
  final String body;
  @override
  List<Object?> get props => [body];
}

final class MessagingChannelChanged extends MessagingAutomationEvent {
  const MessagingChannelChanged(this.channel);
  final MessageChannel channel;
  @override
  List<Object?> get props => [channel];
}

final class MessagingLaunchRequested extends MessagingAutomationEvent {
  const MessagingLaunchRequested();
}

final class MessagingDismissed extends MessagingAutomationEvent {
  const MessagingDismissed();
}
