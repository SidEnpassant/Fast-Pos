import 'package:inventopos/domain/automation/failures/automation_failure.dart';
import 'package:inventopos/domain/messaging/entities/outbound_message.dart';

typedef MessagingResult = ({AutomationFailure? failure});

abstract class OutboundMessagingPort {
  Future<MessagingResult> launch(OutboundMessage message);
}
