import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'pin_service.dart';

/// In-memory unlock state + persisted lockout counter.
///
/// Unlock lives in memory ONLY: every cold start requires the PIN.
/// Lockout (fail count + lockedUntil) is persisted in the Hive `settings`
/// box so a restart does not reset a lockout.
class SessionState extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  SessionState({required PinService pinService}) : _pinService = pinService {
    _loadLockout();
  }

  final PinService _pinService;

  // ── Unlock state (in memory only) ─────────────────────────────

  bool _unlocked = false;
  bool get unlocked => _unlocked;

  // ── Lockout (persisted) ───────────────────────────────────────

  static const String _settingsBox = 'settings';
  static const String _lockKey = 'pin_lock';
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);

  int _failCount = 0;
  int get failCount => _failCount;

  DateTime? _lockedUntil;

  /// Seconds remaining in the lockout, or 0 if not locked.
  int get lockoutRemaining {
    if (_lockedUntil == null) return 0;
    final diff = _lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get isLockedOut => lockoutRemaining > 0;

  /// Whether a PIN has been configured.
  Future<bool> get isPinSet => _pinService.isSet();

  // ── Actions ───────────────────────────────────────────────────

  /// Attempt to unlock with [pin]. Returns `true` on success.
  ///
  /// On failure: increments the counter. After [maxAttempts] failures the
  /// keypad is locked for [lockoutDuration].
  Future<bool> tryUnlock(String pin) async {
    if (isLockedOut) return false;

    final ok = await _pinService.verify(pin);
    if (ok) {
      _unlocked = true;
      _failCount = 0;
      _lockedUntil = null;
      await _persistLockout();
      notifyListeners();
      return true;
    }

    _failCount++;
    if (_failCount >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
    }
    await _persistLockout();
    notifyListeners();
    return false;
  }

  /// Re-lock the app (for example after HIDE or auto-lock).
  void lock() {
    _unlocked = false;
    notifyListeners();
  }

  /// Programmatically unlock session for testing or bypass.
  void unlockForTesting() {
    _unlocked = true;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────

  void _loadLockout() {
    try {
      if (!Hive.isBoxOpen(_settingsBox)) return;
      final data = Hive.box<dynamic>(_settingsBox).get(_lockKey);
      if (data is Map) {
        _failCount = (data['fails'] as int?) ?? 0;
        final until = data['lockedUntil'] as int?;
        if (until != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(until);
          _lockedUntil = dt.isAfter(DateTime.now()) ? dt : null;
        }
        // If we loaded a stale lockout, clear the fail count.
        if (_lockedUntil == null && _failCount >= maxAttempts) {
          _failCount = 0;
          _persistLockout();
        }
      }
    } catch (_) {
      // Safe default: no lockout.
    }
  }

  Future<void> _persistLockout() async {
    try {
      if (!Hive.isBoxOpen(_settingsBox)) return;
      await Hive.box<dynamic>(_settingsBox).put(_lockKey, {
        'fails': _failCount,
        'lockedUntil': _lockedUntil?.millisecondsSinceEpoch,
      });
    } catch (_) {
      // Non-critical; the lockout will just reset on next launch.
    }
  }
}
