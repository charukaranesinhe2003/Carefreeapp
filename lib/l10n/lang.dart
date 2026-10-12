import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

enum Lang { en, si }

/// Read-only view of the user's language.
///
/// The language choice is OWNED BY MEMBER 1 (language selection / onboarding).
/// This service only reads it: it never opens or writes Member 1's `settings`
/// box. Until that box exists the app defaults to English.
class LangService {
  LangService._();

  static const String _settingsBox = 'settings';
  static const String _langKey = 'lang';

  static final ValueNotifier<Lang> current = ValueNotifier<Lang>(Lang.en);

  /// Re-reads `lang` from Member 1's `settings` box if it is already open.
  static void refreshFromStorage() {
    try {
      if (!Hive.isBoxOpen(_settingsBox)) return;
      final value = Hive.box<dynamic>(_settingsBox).get(_langKey);
      current.value = value == 'si' ? Lang.si : Lang.en;
    } catch (_) {
      // Keep the current language if the box has an unexpected shape.
    }
  }

  /// Dev kit and tests only. Does not persist anything.
  static void setPreview(Lang lang) => current.value = lang;
}
