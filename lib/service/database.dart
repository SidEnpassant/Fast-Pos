import 'package:supabase_flutter/supabase_flutter.dart';

/// Legacy helper — kept for parity with older code paths.
class DatabaseMethods {
  Future<void> addUser(String userId, Map<String, dynamic> userInfoMap) async {
    final row = <String, dynamic>{'id': userId};
    userInfoMap.forEach((key, value) {
      switch (key) {
        case 'email':
          row['email'] = value;
        case 'name':
          row['name'] = value;
        case 'imgUrl':
          row['signature_url'] = value;
        default:
          break;
      }
    });
    await Supabase.instance.client.from('profiles').upsert(row);
  }
}
