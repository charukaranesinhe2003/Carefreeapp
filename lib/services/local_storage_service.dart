import 'package:hive_flutter/hive_flutter.dart';
import '../models/cycle_entry.dart';

class LocalStorageService {
  static const String _cycleBoxName = 'cycle_entries';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CycleEntryAdapter());
    await Hive.openBox<CycleEntry>(_cycleBoxName);
  }

  static Box<CycleEntry> get cycleBox => Hive.box<CycleEntry>(_cycleBoxName);

  static Future<void> saveEntry(CycleEntry entry) async {
    // Generate a unique key based on the date (e.g., YYYY-MM-DD)
    final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
    await cycleBox.put(key, entry);
  }

  static CycleEntry? getEntryForDate(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    return cycleBox.get(key);
  }

  static List<CycleEntry> getAllEntries() {
    return cycleBox.values.toList();
  }

  static Future<void> clearAll() async {
    await cycleBox.clear();
  }
}
