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
      await _client.from('ai_preferences').upsert({
        'user_id': preferences.userId,
        'enabled': preferences.enabled,
        'enhanced_context': preferences.enhancedContext,
        'daily_brief_enabled': preferences.dailyBriefEnabled,
        'reorder_alerts_enabled': preferences.reorderAlertsEnabled,
        'partial_bill_reminders_enabled': preferences.partialBillRemindersEnabled,
        'language': preferences.language,
        'daily_token_budget': preferences.dailyTokenBudget,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
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
    final m = Map<String, dynamic>.from(raw);
    return AiPreferences(
      userId: userId,
      enabled: m['enabled'] as bool? ?? false,
      enhancedContext: m['enhanced_context'] as bool? ?? false,
      dailyBriefEnabled: m['daily_brief_enabled'] as bool? ?? true,
      reorderAlertsEnabled: m['reorder_alerts_enabled'] as bool? ?? true,
      partialBillRemindersEnabled:
          m['partial_bill_reminders_enabled'] as bool? ?? true,
      language: m['language'] as String? ?? 'en',
      dailyTokenBudget: m['daily_token_budget'] as int? ?? 50000,
    );
  }

  Future<void> _writeLocal(AiPreferences p) async {
    await _box.put(p.userId, {
      'enabled': p.enabled,
      'enhanced_context': p.enhancedContext,
      'daily_brief_enabled': p.dailyBriefEnabled,
      'reorder_alerts_enabled': p.reorderAlertsEnabled,
      'partial_bill_reminders_enabled': p.partialBillRemindersEnabled,
      'language': p.language,
      'daily_token_budget': p.dailyTokenBudget,
    });
  }

  AiPreferences _fromRow(String userId, Map<String, dynamic> row) =>
      AiPreferences(
        userId: userId,
        enabled: row['enabled'] as bool? ?? false,
        enhancedContext: row['enhanced_context'] as bool? ?? false,
        dailyBriefEnabled: row['daily_brief_enabled'] as bool? ?? true,
        reorderAlertsEnabled: row['reorder_alerts_enabled'] as bool? ?? true,
        partialBillRemindersEnabled:
            row['partial_bill_reminders_enabled'] as bool? ?? true,
        language: row['language'] as String? ?? 'en',
        dailyTokenBudget: row['daily_token_budget'] as int? ?? 50000,
      );
}
