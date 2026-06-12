import 'package:bloc/bloc.dart';
import 'package:inventopos/application/messaging/build_message_use_cases.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_event.dart';
import 'package:inventopos/presentation/messaging/bloc/messaging_automation_state.dart';

class MessagingAutomationBloc
    extends Bloc<MessagingAutomationEvent, MessagingAutomationState> {
  MessagingAutomationBloc(this._launch)
      : super(const MessagingAutomationState()) {
    on<MessagingPreviewRequested>(_onPreview);
    on<MessagingBodyEdited>(_onEdit);
    on<MessagingChannelChanged>(_onChannel);
    on<MessagingLaunchRequested>(_onLaunch);
    on<MessagingDismissed>(_onDismiss);
  }

  final LaunchOutboundMessageUseCase _launch;

  void _onPreview(
    MessagingPreviewRequested event,
    Emitter<MessagingAutomationState> emit,
  ) {
    emit(state.copyWith(
      preview: event.message,
      prefs: event.prefs,
      clearError: true,
    ));
  }

  void _onEdit(
    MessagingBodyEdited event,
    Emitter<MessagingAutomationState> emit,
  ) {
    final p = state.preview;
    if (p == null) return;
    emit(state.copyWith(
      preview: OutboundMessage(
        channel: p.channel,
        phone: p.phone,
        body: event.body,
        filePath: p.filePath,
        templateId: p.templateId,
        recipientName: p.recipientName,
      ),
    ));
  }

  void _onChannel(
    MessagingChannelChanged event,
    Emitter<MessagingAutomationState> emit,
  ) {
    final p = state.preview;
    if (p == null) return;
    emit(state.copyWith(
      preview: OutboundMessage(
        channel: event.channel,
        phone: p.phone,
        body: p.body,
        filePath: p.filePath,
        templateId: p.templateId,
        recipientName: p.recipientName,
      ),
    ));
  }

  Future<void> _onLaunch(
    MessagingLaunchRequested event,
    Emitter<MessagingAutomationState> emit,
  ) async {
    final p = state.preview;
    final prefs = state.prefs;
    if (p == null || prefs == null) return;
    emit(state.copyWith(launching: true, clearError: true));
    final err = await _launch(
      message: p,
      prefs: prefs as AiPreferences,
    );
    emit(state.copyWith(
      launching: false,
      error: err,
      clearPreview: err == null,
    ));
  }

  void _onDismiss(
    MessagingDismissed event,
    Emitter<MessagingAutomationState> emit,
  ) {
    emit(const MessagingAutomationState());
  }
}
