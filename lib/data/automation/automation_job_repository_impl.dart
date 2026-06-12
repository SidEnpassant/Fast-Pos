import 'package:inventopos/domain/automation/entities/automation_job.dart';
import 'package:inventopos/domain/automation/entities/automation_trigger.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AutomationJobRepositoryImpl implements AutomationJobPort {
  AutomationJobRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  @override
  Future<List<AutomationJob>> listForUser(String userId) async {
    try {
      final rows = await _client
          .from('automation_jobs')
          .select()
          .eq('user_id', userId);
      return (rows as List)
          .map((e) => _fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> ensureDefaults(String userId) async {
    final existing = await listForUser(userId);
    final existingTypes = existing.map((j) => j.triggerType).toSet();
    for (final trigger in AutomationTrigger.values) {
      if (existingTypes.contains(trigger.value)) continue;
      try {
        await _client.from('automation_jobs').insert({
          'id': _uuid.v4(),
          'user_id': userId,
          'trigger_type': trigger.value,
          'cron_expression': trigger.defaultCron,
          'enabled': true,
          'config_json': {},
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> syncFromPreferences(
    String userId,
    Map<String, bool> jobEnabled,
  ) async {
    await ensureDefaults(userId);
    final jobs = await listForUser(userId);
    for (final job in jobs) {
      final enabled = jobEnabled[job.triggerType];
      if (enabled == null || enabled == job.enabled) continue;
      try {
        await _client
            .from('automation_jobs')
            .update({'enabled': enabled}).eq('id', job.id);
      } catch (_) {}
    }
  }

  @override
  Future<void> toggleJob(String jobId, bool enabled) async {
    try {
      await _client
          .from('automation_jobs')
          .update({'enabled': enabled}).eq('id', jobId);
    } catch (_) {}
  }

  AutomationJob _fromRow(Map<String, dynamic> row) => AutomationJob(
        id: row['id']?.toString() ?? '',
        userId: row['user_id']?.toString() ?? '',
        triggerType: row['trigger_type']?.toString() ?? '',
        cronExpression: row['cron_expression']?.toString(),
        enabled: row['enabled'] as bool? ?? true,
        lastRunAt: row['last_run_at'] != null
            ? DateTime.parse(row['last_run_at'].toString())
            : null,
        configJson: Map<String, dynamic>.from(
          row['config_json'] as Map? ?? {},
        ),
      );
}
