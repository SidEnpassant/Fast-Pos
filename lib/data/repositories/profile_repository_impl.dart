import 'dart:io';

import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/user_profile_mapper.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<UserProfile>>? watchProfileForCurrentUser() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return guardSupabasePostgresStream(
      _client.from('profiles').stream(primaryKey: ['id']).eq('id', uid).map(
            (rows) => rows.map(UserProfileMapper.fromSupabaseRow).toList(),
          ),
    );
  }

  @override
  Future<UserProfile?> fetchCurrentUserProfileSnapshot() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return UserProfileMapper.fromSupabaseRow(row);
  }

  @override
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> columns,
  }) async {
    if (columns.isEmpty) return;
    await _client.from('profiles').update(columns).eq('id', userId);
  }

  @override
  Future<void> updateProfileFieldByLogicalKey({
    required String userId,
    required String fieldKey,
    required String value,
  }) async {
    final column = SupabaseMappers.profileColumnForField(fieldKey);
    if (column == null) {
      throw ArgumentError.value(fieldKey, 'fieldKey', 'Unknown profile field');
    }
    await updateProfileFields(userId: userId, columns: {column: value});
  }

  @override
  Future<void> replaceSignatureFromLocalFile({
    required String userId,
    required String localFilePath,
  }) async {
    final path =
        '$userId/signature_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucket = _client.storage.from('signatures');
    await bucket.upload(
      path,
      File(localFilePath),
      fileOptions: const FileOptions(upsert: true),
    );
    final url = bucket.getPublicUrl(path);
    await _client
        .from('profiles')
        .update({'signature_url': url}).eq('id', userId);
  }
}
