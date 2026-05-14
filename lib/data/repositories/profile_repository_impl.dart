import 'package:inventopos/core/supabase/guard_supabase_postgres_stream.dart';
import 'package:inventopos/data/mappers/user_profile_mapper.dart';
import 'package:inventopos/domain/entities/user_profile.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';
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
}
