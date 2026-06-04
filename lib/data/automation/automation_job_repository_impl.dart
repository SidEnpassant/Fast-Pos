import 'package:inventopos/domain/automation/entities/automation_job.dart';
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
    if (existing.any((j) => j.triggerType == 'daily_briefing')) return;
    try {
      await _client.from('automation_jobs').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'trigger_type': 'daily_briefing',
        'cron_expression': '0 8 * * *',
        'enabled': true,
        'config_json': {},
      });
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
