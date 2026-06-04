import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

/// Which automations may run without extra confirmation.
abstract final class AutomationPolicy {
  static bool canRunDailyBrief(AiPreferences prefs) =>
      prefs.enabled && prefs.dailyBriefEnabled;

  static bool canRunReorderAlerts(AiPreferences prefs) =>
      prefs.enabled && prefs.reorderAlertsEnabled;

  static bool canInvokeCloudAi(AiPreferences prefs) => prefs.enabled;
}
