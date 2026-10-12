import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_log.dart';

class DailyLogStore {
  static const String _boxName = 'daily_logs_box';
  static late Box<DailyLog> _box;

  static Future<void> init() async {
    Hive.registerAdapter(DailyLogAdapter());
    _box = await Hive.openBox<DailyLog>(_boxName);
  }

  static ValueListenable<Box<DailyLog>> listenToLogs() {
    return _box.listenable();
  }

  // CREATE / UPDATE
  static Future<void> saveLog(DailyLog log) async {
    String key = "${log.date.year}-${log.date.month}-${log.date.day}";
    await _box.put(key, log);
  }

  // READ
  static DailyLog? getLogForDate(DateTime date) {
    String key = "${date.year}-${date.month}-${date.day}";
    return _box.get(key);
  }

  // READ ALL
  static List<DailyLog> getAllLogs() {
    return _box.values.toList();
  }

  // DELETE
  static Future<void> deleteLog(DateTime date) async {
    String key = "${date.year}-${date.month}-${date.day}";
    await _box.delete(key);
  }

  // CLEAR ALL
  static Future<void> clearAll() async {
    await _box.clear();
  }
}
