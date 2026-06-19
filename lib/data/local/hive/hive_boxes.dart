/// Hive box names for offline-first storage.
abstract final class HiveBoxes {
  static const products = 'products';
  static const bills = 'bills';
  static const expenses = 'expenses';
  static const customers = 'customers';
  static const outbox = 'sync_outbox';
  static const searchTokens = 'search_tokens';
  static const printers = 'printers';
  static const billAudit = 'bill_audit';
  static const syncCursors = 'sync_cursors';
  static const aiPreferences = 'ai_preferences';
  static const aiRequestQueue = 'ai_request_queue';
  static const aiBriefingCache = 'ai_briefing_cache';
  static const suppliers = 'suppliers';
  static const purchaseOrders = 'purchase_orders';
  static const cashRegister = 'cash_register';
  static const loyaltyConfig = 'loyalty_config';
  static const stockAudits = 'stock_audits';
  static const stockAuditLines = 'stock_audit_lines';
}
