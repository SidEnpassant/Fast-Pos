import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/automation/entities/automation_trigger.dart';
import 'package:inventopos/domain/automation/policies/automation_policy.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';

class SyncAutomationJobsFromPrefsUseCase {
  SyncAutomationJobsFromPrefsUseCase(this._jobs);

  final AutomationJobPort _jobs;

  Future<void> call(AiPreferences prefs) async {
    if (!prefs.enabled) return;
    await _jobs.ensureDefaults(prefs.userId);
    await _jobs.syncFromPreferences(prefs.userId, {
      AutomationTrigger.dailyBriefing.value:
          AutomationPolicy.canRunDailyBrief(prefs),
      AutomationTrigger.partialBillScan.value:
          AutomationPolicy.canRunPartialBillReminders(prefs),
      AutomationTrigger.lowStockScan.value:
          AutomationPolicy.canRunReorderAlerts(prefs),
      AutomationTrigger.creditExposureScan.value:
          AutomationPolicy.canRunCreditAlerts(prefs),
      AutomationTrigger.deadStockScan.value:
          AutomationPolicy.canRunDeadStockAlerts(prefs),
      AutomationTrigger.eodSummary.value:
          AutomationPolicy.canRunEodSummary(prefs),
      AutomationTrigger.weeklyDigest.value: prefs.weeklyDigestEnabled,
      AutomationTrigger.expenseSpikeScan.value: prefs.expenseAlertsEnabled,
      AutomationTrigger.reorderDigest.value:
          AutomationPolicy.canRunReorderAlerts(prefs),
    });
  }
}
