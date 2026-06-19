import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/entities/credit_note.dart';

class CreditNotesState extends Equatable {
  const CreditNotesState({
    this.notes = const [],
    this.loading = true,
  });

  final List<CreditNote> notes;
  final bool loading;

  CreditNotesState copyWith({
    List<CreditNote>? notes,
    bool? loading,
  }) {
    return CreditNotesState(
      notes: notes ?? this.notes,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object> get props => [notes, loading];
}
