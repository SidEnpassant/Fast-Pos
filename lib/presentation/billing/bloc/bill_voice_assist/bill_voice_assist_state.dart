import 'package:equatable/equatable.dart';

class BillVoiceAssistState extends Equatable {
  const BillVoiceAssistState({
    this.isListening = false,
    this.transcript = '',
  });

  final bool isListening;
  final String transcript;

  BillVoiceAssistState copyWith({
    bool? isListening,
    String? transcript,
  }) {
    return BillVoiceAssistState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  List<Object?> get props => [isListening, transcript];
}
