import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class ReminderAlerts {
  static const _channel = MethodChannel('find_help/reminders');

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> prepare() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('prepare') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> sync(List<Reminder> reminders) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('sync', {
        'reminders': [
          for (final reminder in reminders)
            if (!reminder.done && reminder.atMillis != null)
              {
                'id': reminder.id,
                'title': reminder.title,
                'body': reminder.place.isEmpty ? 'Time for your pharmacy reminder' : reminder.place,
                'at': reminder.atMillis,
              },
        ],
      });
    } catch (_) {}
  }
}
