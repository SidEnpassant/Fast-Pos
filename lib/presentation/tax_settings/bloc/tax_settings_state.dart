import 'package:equatable/equatable.dart';

enum TaxSettingsStatus { initial, loading, success, failure }

class TaxSettingsState extends Equatable {
  const TaxSettingsState({
    this.status = TaxSettingsStatus.initial,
    this.gstin = '',
    this.stateCode = '',
    this.isComposition = false,
    this.error = '',
  });

  final TaxSettingsStatus status;
  final String gstin;
  final String stateCode;
  final bool isComposition;
  final String error;

  TaxSettingsState copyWith({
    TaxSettingsStatus? status,
    String? gstin,
    String? stateCode,
    bool? isComposition,
    String? error,
  }) {
    return TaxSettingsState(
      status: status ?? this.status,
      gstin: gstin ?? this.gstin,
      stateCode: stateCode ?? this.stateCode,
      isComposition: isComposition ?? this.isComposition,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, gstin, stateCode, isComposition, error];
}
