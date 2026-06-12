import 'package:inventopos/domain/automation/entities/automation_job.dart';

abstract class AutomationJobPort {
  Future<List<AutomationJob>> listForUser(String userId);

  Future<void> ensureDefaults(String userId);

  Future<void> syncFromPreferences(String userId, Map<String, bool> jobEnabled);

  Future<void> toggleJob(String jobId, bool enabled);
}
