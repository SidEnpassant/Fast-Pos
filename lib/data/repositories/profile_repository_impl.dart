import 'package:inventopos/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>>? watchProfileForCurrentUser() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return _client.from('profiles').stream(primaryKey: ['id']).eq('id', uid);
  }
}
