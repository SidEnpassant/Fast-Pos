import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';

class BillingCopilotState extends Equatable {
  const BillingCopilotState({
    this.isListening = false,
    this.transcript = '',
    this.parsing = false,
    this.pendingCommand,
    this.parseError,
    this.suggestions = const [],
    this.prefix = '',
    this.loadingSuggestions = false,
  });

  final bool isListening;
  final String transcript;
  final bool parsing;
  final VoiceBillCommand? pendingCommand;
  final String? parseError;
  final List<BillingSuggestion> suggestions;
  final String prefix;
  final bool loadingSuggestions;

  bool get hasPendingLines =>
      pendingCommand != null && pendingCommand!.lines.isNotEmpty;

  BillingCopilotState copyWith({
    bool? isListening,
    String? transcript,
    bool? parsing,
    VoiceBillCommand? pendingCommand,
    bool clearPending = false,
    String? parseError,
    List<BillingSuggestion>? suggestions,
    String? prefix,
    bool? loadingSuggestions,
  }) =>
      BillingCopilotState(
        isListening: isListening ?? this.isListening,
        transcript: transcript ?? this.transcript,
        parsing: parsing ?? this.parsing,
        pendingCommand:
            clearPending ? null : (pendingCommand ?? this.pendingCommand),
        parseError: parseError,
        suggestions: suggestions ?? this.suggestions,
        prefix: prefix ?? this.prefix,
        loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
      );

  @override
  List<Object?> get props => [
        isListening,
        transcript,
        parsing,
        pendingCommand,
        parseError,
        suggestions,
        prefix,
        loadingSuggestions,
      ];
}
