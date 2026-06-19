import 'package:equatable/equatable.dart';

abstract class CreditNotesEvent extends Equatable {
  const CreditNotesEvent();

  @override
  List<Object> get props => [];
}

class CreditNotesStarted extends CreditNotesEvent {
  const CreditNotesStarted(this.userId);
  final String userId;

  @override
  List<Object> get props => [userId];
}

class CreditNotesUpdated extends CreditNotesEvent {
  const CreditNotesUpdated(this.notes);
  final List<dynamic> notes; // actually List<CreditNote>

  @override
  List<Object> get props => [notes];
}
