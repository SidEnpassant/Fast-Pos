import 'package:equatable/equatable.dart';

sealed class RegistrationSuccessEvent extends Equatable {
  const RegistrationSuccessEvent();

  @override
  List<Object?> get props => [];
}

final class RegistrationSuccessSliderChanged extends RegistrationSuccessEvent {
  const RegistrationSuccessSliderChanged(this.normalizedPosition);

  final double normalizedPosition;

  @override
  List<Object?> get props => [normalizedPosition];
}

final class RegistrationSuccessSliderReleased extends RegistrationSuccessEvent {
  const RegistrationSuccessSliderReleased();
}
