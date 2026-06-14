import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/core/utils/stream_utils.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();
  final Map<String, Future<void>> _pullInFlight = {};
  DateTime? _lastPullAt;

  Box<Map> get _box => Hive.box<Map>(HiveBoxes.expenses);

  @override
  Stream<List<Expense>> watchExpensesForUser(String userId) {
    unawaited(_pull(userId));
    return hiveWatchStream(
      events: _box.watch(),
      read: () => _list(userId),
    );
  }

  List<Expense> _list(String userId) {
    return _box.values
        .map((m) => _fromMap(Map<String, dynamic>.from(m)))
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
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
          .from('expenses')
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
      if (kDebugMode) debugPrint('ExpenseRepo._pullOnce failed: $e');
    }
  }

  String _getCursor(String userId) {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    return b.get('expenses:$userId')?['last_created'] as String? ??
        '1970-01-01T00:00:00Z';
  }

  Future<void> _setCursor(String userId, String cursor) async {
    final b = Hive.box<Map>(HiveBoxes.syncCursors);
    await b.put('expenses:$userId', {'last_created': cursor});
  }

  @override
  Future<Expense> createExpense({
    required String userId,
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? note,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final row = {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'note': note,
      'created_at': now.toUtc().toIso8601String(),
      'sync_status': 'pending',
    };
    await _box.put(id, row);
    try {
      await _client.from('expenses').insert({
        'id': id,
        'user_id': userId,
        'category': category,
        'amount': amount,
        'expense_date': row['expense_date'],
        'note': note,
      });
      row['sync_status'] = 'synced';
      await _box.put(id, row);
    } catch (e) {
      if (kDebugMode) debugPrint('ExpenseRepo.createExpense failed: $e');
    }
    return _fromMap(row);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    try {
      await _client.from('expenses').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) debugPrint('ExpenseRepo.deleteExpense failed: $e');
    }
  }

  Expense _fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        category: m['category'] as String,
        amount: (m['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(m['expense_date'] as String),
        note: m['note'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        syncStatus: m['sync_status'] as String? ?? 'synced',
      );
}
