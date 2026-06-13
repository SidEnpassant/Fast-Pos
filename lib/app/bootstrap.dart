import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/notifications/notification_background_poll.dart';
import 'package:inventopos/app/local_notifications_holder.dart';
import 'package:inventopos/core/router/app_router.dart';
import 'package:inventopos/data/local/hive/local_store.dart';
import 'package:inventopos/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Composition-root bootstrap (no UI): binding + remote SDK + local store.
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SupabaseConfig.ensureConfigured();
  await LocalStore.init();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await appLocalNotifications.initialize(
    onNotificationTap: (_) {
      final ctx = appRootNavigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).push('/app/notifications');
      }
    },
  );
  try {
    await registerNotificationBackgroundPoll();
  } catch (_) {}
}
