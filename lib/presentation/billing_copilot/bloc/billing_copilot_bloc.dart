import 'package:bloc/bloc.dart';
import 'package:inventopos/application/ai/get_billing_suggestions_use_case.dart';
import 'package:inventopos/application/ai/parse_voice_bill_command_use_case.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/services/voice_command_validator.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/presentation/billing_copilot/bloc/billing_copilot_event.dart';
import 'package:inventopos/presentation/billing_copilot/bloc/billing_copilot_state.dart';
import 'package:speech_to_text/speech_to_text.dart';

class BillingCopilotBloc extends Bloc<BillingCopilotEvent, BillingCopilotState> {
  BillingCopilotBloc(
    this._parse,
    this._suggestions,
    this._speech,
  ) : super(const BillingCopilotState()) {
    on<BillingCopilotStarted>(_onStarted);
    on<BillingCopilotListeningToggled>(_onListening);
    on<BillingCopilotTranscriptUpdated>(_onTranscript);
    on<BillingCopilotParseRequested>(_onParse);
    on<BillingCopilotParseCompleted>(_onParseCompleted);
    on<BillingCopilotPrefixChanged>(_onPrefix);
    on<BillingCopilotSuggestionsReceived>(_onSuggestions);
    on<BillingCopilotDismissed>(_onDismissed);
  }

  final ParseVoiceBillCommandUseCase _parse;
  final GetBillingSuggestionsUseCase _suggestions;
  final SpeechToText _speech;

  String _userId = '';
  List<Product> _products = const [];

  void _onStarted(
    BillingCopilotStarted event,
    Emitter<BillingCopilotState> emit,
  ) {
    _userId = event.userId;
    _products = event.products;
  }

  Future<void> _onListening(
    BillingCopilotListeningToggled event,
    Emitter<BillingCopilotState> emit,
  ) async {
    if (state.isListening) {
      await _speech.stop();
      emit(state.copyWith(isListening: false));
      return;
    }
    final ok = await _speech.initialize();
    if (!ok) return;
    emit(state.copyWith(isListening: true, transcript: ''));
    await _speech.listen(
      onResult: (r) => add(BillingCopilotTranscriptUpdated(r.recognizedWords)),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  void _onTranscript(
    BillingCopilotTranscriptUpdated event,
    Emitter<BillingCopilotState> emit,
  ) {
    emit(state.copyWith(transcript: event.text));
  }

  Future<void> _onParse(
    BillingCopilotParseRequested event,
    Emitter<BillingCopilotState> emit,
  ) async {
    final text = state.transcript.trim();
    if (text.isEmpty || _userId.isEmpty) return;
    emit(state.copyWith(parsing: true, parseError: null));
    await _speech.stop();
    emit(state.copyWith(isListening: false));

    final result = await _parse(
      userId: _userId,
      transcript: text,
      products: _products,
    );
    switch (result) {
      case AiSuccess(:final value):
        final err = VoiceCommandValidator.validate(value);
        add(BillingCopilotParseCompleted(
          err == null ? value : null,
          err,
        ));
      case AiError(:final failure):
        add(BillingCopilotParseCompleted(null, failure.message));
    }
  }

  void _onParseCompleted(
    BillingCopilotParseCompleted event,
    Emitter<BillingCopilotState> emit,
  ) {
    emit(state.copyWith(
      parsing: false,
      pendingCommand: event.command,
      parseError: event.error,
    ));
  }

  Future<void> _onPrefix(
    BillingCopilotPrefixChanged event,
    Emitter<BillingCopilotState> emit,
  ) async {
    emit(state.copyWith(
      prefix: event.prefix,
      loadingSuggestions: event.prefix.length >= 2,
    ));
    if (event.prefix.length < 2 || _userId.isEmpty) {
      add(const BillingCopilotSuggestionsReceived([]));
      return;
    }
    final list = await _suggestions(
      userId: _userId,
      prefix: event.prefix,
      products: _products,
      basketProductIds: const [],
    );
    add(BillingCopilotSuggestionsReceived(list));
  }

  void _onSuggestions(
    BillingCopilotSuggestionsReceived event,
    Emitter<BillingCopilotState> emit,
  ) {
    emit(state.copyWith(
      suggestions: event.suggestions,
      loadingSuggestions: false,
    ));
  }

  void _onDismissed(
    BillingCopilotDismissed event,
    Emitter<BillingCopilotState> emit,
  ) {
    emit(const BillingCopilotState());
  }

  @override
  Future<void> close() async {
    await _speech.stop();
    return super.close();
  }
}
