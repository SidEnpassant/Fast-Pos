import 'package:inventopos/domain/ai/entities/ai_preferences.dart';

/// Which automations may run without extra confirmation.
abstract final class AutomationPolicy {
  static bool canRunDailyBrief(AiPreferences prefs) =>
      prefs.enabled && prefs.dailyBriefEnabled;

  static bool canRunReorderAlerts(AiPreferences prefs) =>
      prefs.enabled && prefs.reorderAlertsEnabled;

  static bool canRunPartialBillReminders(AiPreferences prefs) =>
      prefs.enabled && prefs.partialBillRemindersEnabled;

  static bool canRunCreditAlerts(AiPreferences prefs) =>
      prefs.enabled && prefs.creditAlertsEnabled;

  static bool canRunDeadStockAlerts(AiPreferences prefs) =>
      prefs.enabled && prefs.deadStockAlertsEnabled;

  static bool canRunMarginAlerts(AiPreferences prefs) =>
      prefs.enabled && prefs.marginAlertsEnabled;

  static bool canRunBillSanityCheck(AiPreferences prefs) =>
      prefs.enabled && prefs.billSanityCheckEnabled;

  static bool canRunEodSummary(AiPreferences prefs) =>
      prefs.enabled && prefs.eodSummaryEnabled;

  static bool canRunOpeningSnapshot(AiPreferences prefs) =>
      prefs.enabled && prefs.openingSnapshotEnabled;

  static bool canRunRepeatOrder(AiPreferences prefs) =>
      prefs.enabled && prefs.repeatOrderEnabled;

  static bool canAutoShareReceipt(AiPreferences prefs) =>
      prefs.enabled && prefs.autoReceiptShareEnabled;

  static bool canSendPaymentThankYou(AiPreferences prefs) =>
      prefs.enabled && prefs.paymentThankYouEnabled;

  static bool canLaunchOutboundMessage(AiPreferences prefs) => prefs.enabled;

  static bool canInvokeCloudAi(AiPreferences prefs) => prefs.enabled;
}
