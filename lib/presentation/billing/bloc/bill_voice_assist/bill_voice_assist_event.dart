import 'package:equatable/equatable.dart';

sealed class BillVoiceAssistEvent extends Equatable {
  const BillVoiceAssistEvent();

  @override
  List<Object?> get props => [];
}

final class BillVoiceAssistTogglePressed extends BillVoiceAssistEvent {
  const BillVoiceAssistTogglePressed();
}

final class BillVoiceAssistWordsHeard extends BillVoiceAssistEvent {
  const BillVoiceAssistWordsHeard(this.words);

  final String words;

  @override
  List<Object?> get props => [words];
}
