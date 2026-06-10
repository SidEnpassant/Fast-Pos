import 'package:hive_flutter/hive_flutter.dart';
import 'package:inventopos/data/local/hive/hive_boxes.dart';

/// Opens Hive boxes during app bootstrap.
class LocalStore {
  LocalStore._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(HiveBoxes.products),
      Hive.openBox<Map>(HiveBoxes.bills),
      Hive.openBox<Map>(HiveBoxes.expenses),
      Hive.openBox<Map>(HiveBoxes.customers),
      Hive.openBox<Map>(HiveBoxes.outbox),
      Hive.openBox<Map>(HiveBoxes.searchTokens),
      Hive.openBox<Map>(HiveBoxes.printers),
      Hive.openBox<Map>(HiveBoxes.billAudit),
      Hive.openBox<Map>(HiveBoxes.syncCursors),
      Hive.openBox<Map>(HiveBoxes.aiPreferences),
      Hive.openBox<Map>(HiveBoxes.aiRequestQueue),
      Hive.openBox<Map>(HiveBoxes.aiBriefingCache),
    ]);
    _initialized = true;
  }

  static Box<Map> box(String name) => Hive.box<Map>(name);
}
