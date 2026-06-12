import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';

class MessagingAutomationState extends Equatable {
  const MessagingAutomationState({
    this.preview,
    this.prefs,
    this.launching = false,
    this.error,
    this.queue = const [],
    this.queueLoading = false,
  });

  final OutboundMessage? preview;
  final dynamic prefs;
  final bool launching;
  final String? error;
  final List<OutboundMessage> queue;
  final bool queueLoading;

  MessagingAutomationState copyWith({
    OutboundMessage? preview,
    dynamic prefs,
    bool? launching,
    String? error,
    bool clearPreview = false,
    bool clearError = false,
    List<OutboundMessage>? queue,
    bool? queueLoading,
  }) =>
      MessagingAutomationState(
        preview: clearPreview ? null : (preview ?? this.preview),
        prefs: prefs ?? this.prefs,
        launching: launching ?? this.launching,
        error: clearError ? null : (error ?? this.error),
        queue: queue ?? this.queue,
        queueLoading: queueLoading ?? this.queueLoading,
      );

  @override
  List<Object?> get props => [
        preview,
        launching,
        error,
        queue,
        queueLoading,
      ];
}
