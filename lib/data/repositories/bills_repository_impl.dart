import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillsRepositoryImpl implements BillsRepository {
  BillsRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchBillsForCurrentUser() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream.empty();
    }
    return _client
        .from('bills')
        .stream(primaryKey: ['id']).eq('user_id', uid);
  }
}
