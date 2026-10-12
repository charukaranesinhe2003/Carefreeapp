import 'package:hive/hive.dart';
import '../models/reminder.dart';

class ReminderService {
  static const String _boxName = 'settings';
  static const String _remindersKey = 'custom_reminders';

  static List<Reminder> getReminders() {
    final box = Hive.box<dynamic>(_boxName);
    final List<dynamic> data = box.get(_remindersKey, defaultValue: []);
    return data.map((e) => Reminder.fromMap(e as Map<dynamic, dynamic>)).toList();
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final box = Hive.box<dynamic>(_boxName);
    final List<Map<String, dynamic>> data = reminders.map((e) => e.toMap()).toList();
    await box.put(_remindersKey, data);
  }

  static Future<void> addReminder(Reminder reminder) async {
    final reminders = getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    final reminders = getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await saveReminders(reminders);
    }
  }

  static Future<void> deleteReminder(String id) async {
    final reminders = getReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
  }
}
