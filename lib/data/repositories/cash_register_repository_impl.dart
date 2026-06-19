import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/cash_entry.dart';
import 'package:inventopos/domain/repositories/cash_register_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CashRegisterRepositoryImpl implements CashRegisterRepository {
  CashRegisterRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, Future<void>> _pullInFlight = {};
  DateTime? _lastPullAt;

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.cashRegister);

  @override
  Stream<List<CashEntry>> watchEntriesForDate(String userId, DateTime date) {
    unawaited(_pull(userId));
    return hiveWatchStream(
      events: _box.watch(),
      read: () => _listForDate(userId, date),
    );
  }

  @override
  Stream<List<CashEntry>> watchEntriesForRange(String userId, DateTime start, DateTime end) {
    unawaited(_pull(userId));
    return hiveWatchStream(
      events: _box.watch(),
      read: () => _listForRange(userId, start, end),
    );
  }

  List<CashEntry> _listForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _listForRange(userId, startOfDay, endOfDay);
  }

  List<CashEntry> _listForRange(String userId, DateTime start, DateTime end) {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .where((e) =>
            e.userId == userId &&
            e.entryDate.isAfter(start.subtract(const Duration(microseconds: 1))) &&
            e.entryDate.isBefore(end))
        .toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  Future<void> _pull(String userId) async {
    if (_lastPullAt != null &&
        DateTime.now().difference(_lastPullAt!) < const Duration(seconds: 30)) {
      return;
    }

    final inFlight = _pullInFlight[userId];
    if (inFlight != null) return inFlight;

    final future = _pullOnce(userId);
    _pullInFlight[userId] = future;
    try {
      await future;
      _lastPullAt = DateTime.now();
    } finally {
      if (identical(_pullInFlight[userId], future)) {
        _pullInFlight.remove(userId);
      }
    }
  }

  Future<void> _pullOnce(String userId) async {
    try {
      final cursor = _getCursor(userId);
      final rows = await _client
          .from('cash_register')
          .select()
          .eq('user_id', userId)
          .gt('created_at', cursor)
          .order('created_at');

      String? latest = cursor;
      for (final raw in rows as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        await _box.put(m['id'], m);
        final createdAt = m['created_at'] as String;
        if (latest == null || createdAt.compareTo(latest) > 0) {
          latest = createdAt;
        }
      }
      if (latest != cursor) {
        await _setCursor(userId, latest!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CashRegisterRepo._pullOnce failed: $e');
    }
  }

  String _getCursor(String userId) {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    return b.get('cash_register:$userId')?['last_updated'] as String? ??
        '1970-01-01T00:00:00Z';
  }

  Future<void> _setCursor(String userId, String cursor) async {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    await b.put('cash_register:$userId', {'last_updated': cursor});
  }

  @override
  Future<CashEntry> createEntry(CashEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    final row = {
      'id': id,
      'user_id': entry.userId,
      'entry_date': entry.entryDate.toUtc().toIso8601String(),
      'type': entry.type,
      'amount': entry.amount,
      'reference_id': entry.referenceId,
      'reference_type': entry.referenceType,
      'note': entry.note,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _client.from('cash_register').insert(row);
    } catch (e) {
      if (kDebugMode) debugPrint('CashRegisterRepo.createEntry failed: $e');
    }
    await _box.put(id, row);
    return _fromMap(row);
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      await _client.from('cash_register').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) debugPrint('CashRegisterRepo.deleteEntry failed: $e');
    }
    await _box.delete(id);
  }

  CashEntry _fromMap(Map<String, dynamic> m) => CashEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        entryDate: DateTime.parse(m['entry_date'] as String),
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        referenceId: m['reference_id'] as String?,
        referenceType: m['reference_type'] as String?,
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
