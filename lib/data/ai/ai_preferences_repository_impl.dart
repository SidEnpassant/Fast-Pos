import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/data/local/hive/local_store.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiPreferencesRepositoryImpl implements AiPreferencesPort {
  AiPreferencesRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _controller = StreamController<AiPreferences>.broadcast();

  Box<Map> get _box => LocalStore.box(HiveBoxes.aiPreferences);

  @override
  Future<AiPreferences> fetch(String userId) async {
    final cached = _readLocal(userId);
    try {
      final row = await _client
          .from('ai_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row != null) {
        final prefs = _fromRow(userId, Map<String, dynamic>.from(row));
        await _writeLocal(prefs);
        return prefs;
      }
    } catch (_) {}
    if (cached != null) return cached;
    return AiPreferences(userId: userId);
  }

  @override
  Future<void> save(AiPreferences preferences) async {
    await _writeLocal(preferences);
    _controller.add(preferences);
    try {
      await _client.from('ai_preferences').upsert(_toRow(preferences));
    } catch (_) {}
  }

  @override
  Stream<AiPreferences> watch(String userId) async* {
    yield await fetch(userId);
    yield* _controller.stream.where((p) => p.userId == userId);
  }

  AiPreferences? _readLocal(String userId) {
    final raw = _box.get(userId);
    if (raw == null) return null;
    return _fromMap(userId, Map<String, dynamic>.from(raw));
  }

  Future<void> _writeLocal(AiPreferences p) async {
    await _box.put(p.userId, _toMap(p));
  }

  Map<String, dynamic> _toMap(AiPreferences p) => {
        'enabled': p.enabled,
        'enhanced_context': p.enhancedContext,
        'daily_brief_enabled': p.dailyBriefEnabled,
        'reorder_alerts_enabled': p.reorderAlertsEnabled,
        'partial_bill_reminders_enabled': p.partialBillRemindersEnabled,
        'credit_alerts_enabled': p.creditAlertsEnabled,
        'dead_stock_alerts_enabled': p.deadStockAlertsEnabled,
        'margin_alerts_enabled': p.marginAlertsEnabled,
        'bill_sanity_check_enabled': p.billSanityCheckEnabled,
        'eod_summary_enabled': p.eodSummaryEnabled,
        'opening_snapshot_enabled': p.openingSnapshotEnabled,
        'repeat_order_enabled': p.repeatOrderEnabled,
        'auto_receipt_share_enabled': p.autoReceiptShareEnabled,
        'payment_thank_you_enabled': p.paymentThankYouEnabled,
        'expense_alerts_enabled': p.expenseAlertsEnabled,
        'weekly_digest_enabled': p.weeklyDigestEnabled,
        'language': p.language,
        'daily_token_budget': p.dailyTokenBudget,
        'owner_whatsapp_phone': p.ownerWhatsAppPhone,
        'supplier_whatsapp_phone': p.supplierWhatsAppPhone,
        'default_message_channel': p.defaultMessageChannel,
        'merchant_upi_id': p.merchantUpiId,
      };

  Map<String, dynamic> _toRow(AiPreferences p) => {
        'user_id': p.userId,
        ..._toMap(p),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  AiPreferences _fromMap(String userId, Map<String, dynamic> m) =>
      AiPreferences(
        userId: userId,
        enabled: m['enabled'] as bool? ?? false,
        enhancedContext: m['enhanced_context'] as bool? ?? false,
        dailyBriefEnabled: m['daily_brief_enabled'] as bool? ?? true,
        reorderAlertsEnabled: m['reorder_alerts_enabled'] as bool? ?? true,
        partialBillRemindersEnabled:
            m['partial_bill_reminders_enabled'] as bool? ?? true,
        creditAlertsEnabled: m['credit_alerts_enabled'] as bool? ?? true,
        deadStockAlertsEnabled: m['dead_stock_alerts_enabled'] as bool? ?? true,
        marginAlertsEnabled: m['margin_alerts_enabled'] as bool? ?? true,
        billSanityCheckEnabled: m['bill_sanity_check_enabled'] as bool? ?? true,
        eodSummaryEnabled: m['eod_summary_enabled'] as bool? ?? true,
        openingSnapshotEnabled: m['opening_snapshot_enabled'] as bool? ?? true,
        repeatOrderEnabled: m['repeat_order_enabled'] as bool? ?? true,
        autoReceiptShareEnabled:
            m['auto_receipt_share_enabled'] as bool? ?? false,
        paymentThankYouEnabled: m['payment_thank_you_enabled'] as bool? ?? true,
        expenseAlertsEnabled: m['expense_alerts_enabled'] as bool? ?? true,
        weeklyDigestEnabled: m['weekly_digest_enabled'] as bool? ?? true,
        language: m['language'] as String? ?? 'en',
        dailyTokenBudget: m['daily_token_budget'] as int? ?? 50000,
        ownerWhatsAppPhone: m['owner_whatsapp_phone'] as String?,
        supplierWhatsAppPhone: m['supplier_whatsapp_phone'] as String?,
        defaultMessageChannel:
            m['default_message_channel'] as String? ?? 'whatsapp',
        merchantUpiId: m['merchant_upi_id'] as String?,
      );

  AiPreferences _fromRow(String userId, Map<String, dynamic> row) =>
      _fromMap(userId, row);
}
