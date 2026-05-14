import 'package:bloc/bloc.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_event.dart';
import 'package:inventopos/presentation/billing/bloc/bill_voice_assist/bill_voice_assist_state.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Drives speech-to-text for the bill customer name field (main generate screen).
class BillVoiceAssistBloc
    extends Bloc<BillVoiceAssistEvent, BillVoiceAssistState> {
  BillVoiceAssistBloc(this._speech) : super(const BillVoiceAssistState()) {
    on<BillVoiceAssistTogglePressed>(_onTogglePressed);
    on<BillVoiceAssistWordsHeard>(_onWordsHeard);
  }

  final SpeechToText _speech;

  Future<void> _onTogglePressed(
    BillVoiceAssistTogglePressed event,
    Emitter<BillVoiceAssistState> emit,
  ) async {
    if (state.isListening) {
      await _speech.stop();
      emit(state.copyWith(isListening: false));
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      return;
    }

    emit(state.copyWith(isListening: true, transcript: ''));

    await _speech.listen(
      onResult: (result) {
        add(BillVoiceAssistWordsHeard(result.recognizedWords));
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  void _onWordsHeard(
    BillVoiceAssistWordsHeard event,
    Emitter<BillVoiceAssistState> emit,
  ) {
    emit(state.copyWith(transcript: event.words));
  }

  @override
  Future<void> close() async {
    await _speech.stop();
    await super.close();
  }
}
