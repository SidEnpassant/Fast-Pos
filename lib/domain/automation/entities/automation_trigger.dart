/// Scheduled automation job trigger types.
enum AutomationTrigger {
  dailyBriefing('daily_briefing', '0 8 * * *'),
  partialBillScan('partial_bill_scan', '0 9 * * *'),
  lowStockScan('low_stock_scan', '0 8 * * *'),
  creditExposureScan('credit_exposure_scan', '0 9 * * *'),
  deadStockScan('dead_stock_scan', '0 10 * * 1'),
  eodSummary('eod_summary', '0 21 * * *'),
  weeklyDigest('weekly_digest', '0 8 * * 1'),
  expenseSpikeScan('expense_spike_scan', '0 8 * * 1'),
  reorderDigest('reorder_digest', '0 8 * * *');

  const AutomationTrigger(this.value, this.defaultCron);
  final String value;
  final String defaultCron;
}
