import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/ai/entities/billing_suggestion.dart';
import 'package:inventopos/domain/ai/entities/voice_bill_command.dart';
import 'package:inventopos/domain/entities/product.dart';

sealed class BillingCopilotEvent extends Equatable {
  const BillingCopilotEvent();

  @override
  List<Object?> get props => [];
}

final class BillingCopilotStarted extends BillingCopilotEvent {
  const BillingCopilotStarted({required this.userId, required this.products});
  final String userId;
  final List<Product> products;

  @override
  List<Object?> get props => [userId, products];
}

final class BillingCopilotListeningToggled extends BillingCopilotEvent {
  const BillingCopilotListeningToggled();
}

final class BillingCopilotTranscriptUpdated extends BillingCopilotEvent {
  const BillingCopilotTranscriptUpdated(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

final class BillingCopilotParseRequested extends BillingCopilotEvent {
  const BillingCopilotParseRequested();
}

final class BillingCopilotParseCompleted extends BillingCopilotEvent {
  const BillingCopilotParseCompleted(this.command, this.error);
  final VoiceBillCommand? command;
  final String? error;

  @override
  List<Object?> get props => [command, error];
}

final class BillingCopilotPrefixChanged extends BillingCopilotEvent {
  const BillingCopilotPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class BillingCopilotSuggestionsReceived extends BillingCopilotEvent {
  const BillingCopilotSuggestionsReceived(this.suggestions);
  final List<BillingSuggestion> suggestions;

  @override
  List<Object?> get props => [suggestions];
}

final class BillingCopilotApplyConfirmed extends BillingCopilotEvent {
  const BillingCopilotApplyConfirmed();
}

final class BillingCopilotDismissed extends BillingCopilotEvent {
  const BillingCopilotDismissed();
}
