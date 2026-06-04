import 'package:inventopos/domain/automation/entities/automation_job.dart';

abstract class AutomationJobPort {
  Future<List<AutomationJob>> listForUser(String userId);

  Future<void> ensureDefaults(String userId);
}
