import 'package:equatable/equatable.dart';

sealed class TaxSettingsEvent extends Equatable {
  const TaxSettingsEvent();
  @override
  List<Object?> get props => [];
}

class TaxSettingsStarted extends TaxSettingsEvent {
  const TaxSettingsStarted();
}

class TaxSettingsGstinUpdated extends TaxSettingsEvent {
  const TaxSettingsGstinUpdated(this.gstin);
  final String gstin;
  @override
  List<Object?> get props => [gstin];
}

class TaxSettingsStateCodeUpdated extends TaxSettingsEvent {
  const TaxSettingsStateCodeUpdated(this.stateCode);
  final String stateCode;
  @override
  List<Object?> get props => [stateCode];
}

class TaxSettingsCompositionToggled extends TaxSettingsEvent {
  const TaxSettingsCompositionToggled({required this.isComposition});
  final bool isComposition;
  @override
  List<Object?> get props => [isComposition];
}

class TaxSettingsSaved extends TaxSettingsEvent {
  const TaxSettingsSaved();
}
