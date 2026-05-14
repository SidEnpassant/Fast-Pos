import 'package:equatable/equatable.dart';

class RegistrationSuccessState extends Equatable {
  const RegistrationSuccessState({
    this.sliderPosition = 0,
    this.hasTriggeredGo = false,
    this.shouldNavigateToDashboard = false,
  });

  final double sliderPosition;
  final bool hasTriggeredGo;
  final bool shouldNavigateToDashboard;

  RegistrationSuccessState copyWith({
    double? sliderPosition,
    bool? hasTriggeredGo,
    bool? shouldNavigateToDashboard,
  }) {
    return RegistrationSuccessState(
      sliderPosition: sliderPosition ?? this.sliderPosition,
      hasTriggeredGo: hasTriggeredGo ?? this.hasTriggeredGo,
      shouldNavigateToDashboard:
          shouldNavigateToDashboard ?? this.shouldNavigateToDashboard,
    );
  }

  @override
  List<Object?> get props =>
      [sliderPosition, hasTriggeredGo, shouldNavigateToDashboard];
}
