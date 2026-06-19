import 'package:equatable/equatable.dart';

sealed class AutomationFailure extends Equatable {
  const AutomationFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class AutomationConsentDenied extends AutomationFailure {
  const AutomationConsentDenied()
      : super('Automations are disabled in settings');
}

final class AutomationLaunchFailed extends AutomationFailure {
  const AutomationLaunchFailed(super.message);
}

final class AutomationInvalidPhone extends AutomationFailure {
  const AutomationInvalidPhone() : super('Invalid phone number for messaging');
}
