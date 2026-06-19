import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  LoyaltyRepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Box<Map> get _configBox => Hive.box<Map>(HiveBoxes.loyaltyConfig);
  Box<Map> get _customerBox => Hive.box<Map>(HiveBoxes.customers);

  @override
  Future<LoyaltyConfig> getLoyaltyConfig(String userId) async {
    // Try local first
    final local = _configBox.get(userId);
    if (local != null) {
      return LoyaltyConfig.fromJson(Map<String, dynamic>.from(local));
    }

    // Pull from Supabase
    try {
      final res = await _client
          .from('loyalty_config')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (res != null) {
        final config = LoyaltyConfig.fromJson(Map<String, dynamic>.from(res));
        await _configBox.put(userId, config.toJson());
        return config;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('LoyaltyRepo.getLoyaltyConfig failed: $e');
    }

    return const LoyaltyConfig();
  }

  @override
  Future<void> saveLoyaltyConfig(String userId, LoyaltyConfig config) async {
    final data = config.toJson();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      final dbData = Map<String, dynamic>.from(data);
      dbData.remove('min_points_to_redeem');
      await _client.from('loyalty_config').upsert(dbData);
    } catch (e) {
      if (kDebugMode) debugPrint('LoyaltyRepo.saveLoyaltyConfig failed: $e');
    }
    await _configBox.put(userId, data);
  }

  @override
  Future<void> updateCustomerPoints(String customerId, int pointsChange) async {
    final customerRaw = _customerBox.get(customerId);
    if (customerRaw == null) return;

    final customerMap = Map<String, dynamic>.from(customerRaw);
    final currentPoints = (customerMap['loyalty_points'] as num?)?.toInt() ?? 0;
    final newPoints = currentPoints + pointsChange;
    
    customerMap['loyalty_points'] = newPoints;
    customerMap['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      await _client
          .from('customers')
          .update({'loyalty_points': newPoints, 'updated_at': customerMap['updated_at']})
          .eq('id', customerId);
    } catch (e) {
      if (kDebugMode) debugPrint('LoyaltyRepo.updateCustomerPoints failed: $e');
    }
    await _customerBox.put(customerId, customerMap);
  }
}
