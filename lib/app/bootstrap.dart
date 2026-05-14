import 'package:flutter/widgets.dart';
import 'package:inventopos/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Composition-root bootstrap (no UI): binding + remote SDK init.
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}
