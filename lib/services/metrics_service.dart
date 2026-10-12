import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A single timestamped interaction event recorded during testing.
class MetricEvent {
  const MetricEvent({
    required this.name,
    required this.timestamp,
    this.data = const {},
  });

  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        if (data.isNotEmpty) 'data': data,
      };
}

/// In-memory metrics and instrumentation service for Phase 8 user-testing.
///
/// Activated via `--dart-define=TEST_MODE=true` or programmatically via [enableForTesting].
/// Records key user interaction events:
/// - `lock_shown`, `pin_key`, `pin_error`, `unlocked`
/// - `nav`, `article_open`, `save_offline`, `toast_shown`
/// - `hide_tap`, `hide_done`
///
/// Computes:
/// - Time-on-task (unlock -> hide_done)
/// - Tap count
/// - Error counts (wrong PIN attempts)
/// - HIDE latency (target < 2s, aim for < 100ms)
/// - Task success rate
///
/// Privacy guarantee:
/// - All logs stored locally in memory only.
/// - Zero PII, zero participant names, zero network transmissions.
class MetricsService extends ChangeNotifier {
  MetricsService._();

  static final MetricsService instance = MetricsService._();

  /// Whether `--dart-define=TEST_MODE=true` was specified at build time.
  static const bool isTestModeDefined =
      bool.fromEnvironment('TEST_MODE', defaultValue: false);

  bool _forceEnabled = false;

  /// Whether metrics recording is currently active.
  bool get isEnabled => isTestModeDefined || _forceEnabled;

  DateTime? _sessionStart;
  final List<MetricEvent> _events = [];

  List<MetricEvent> get events => List.unmodifiable(_events);
  DateTime? get sessionStart => _sessionStart;

  /// Enable programmatically for test harness / development.
  void enableForTesting({bool enabled = true}) {
    _forceEnabled = enabled;
    notifyListeners();
  }

  /// Start or reset a testing session.
  void startSession() {
    _events.clear();
    _sessionStart = DateTime.now();
    notifyListeners();
  }

  /// Reset all recorded events.
  void reset() {
    _events.clear();
    _sessionStart = null;
    notifyListeners();
  }

  /// Record an interaction event if metrics are enabled.
  void record(String name, [Map<String, dynamic>? data]) {
    if (!isEnabled) return;

    _sessionStart ??= DateTime.now();

    // Deduplicate repeated article_open builds in rapid succession
    if (name == 'article_open' &&
        _events.isNotEmpty &&
        _events.last.name == 'article_open' &&
        _events.last.data['articleId'] == data?['articleId']) {
      return;
    }

    final event = MetricEvent(
      name: name,
      timestamp: DateTime.now(),
      data: data != null ? Map.unmodifiable(data) : const {},
    );

    _events.add(event);
    notifyListeners();
  }

  // ── Metric Computations ────────────────────────────────────────────

  /// Number of wrong PIN attempts recorded.
  int get pinErrorCount => _events.where((e) => e.name == 'pin_error').length;

  /// Number of interactive taps recorded (PIN keys, navigation, saves, hides).
  int get tapCount {
    return _events.where((e) {
      return e.name == 'pin_key' ||
          e.name == 'nav' ||
          e.name == 'save_offline' ||
          e.name == 'hide_tap';
    }).length;
  }

  /// Number of interactive taps recorded after unlock (target: <= 4 taps).
  int get postUnlockTapCount {
    bool passedUnlock = false;
    int count = 0;
    for (final e in _events) {
      if (e.name == 'unlocked') {
        passedUnlock = true;
        continue;
      }
      if (passedUnlock) {
        if (e.name == 'nav' ||
            e.name == 'save_offline' ||
            e.name == 'hide_tap') {
          count++;
        }
      }
    }
    return count;
  }

  /// Latency in milliseconds between tapping HIDE and the stack being cleared.
  int? get hideLatencyMs {
    MetricEvent? tap;
    MetricEvent? done;

    for (final e in _events) {
      if (e.name == 'hide_tap') tap = e;
      if (e.name == 'hide_done') done = e;
    }

    if (tap != null && done != null) {
      return done.timestamp.difference(tap.timestamp).inMilliseconds;
    }
    return null;
  }

  /// Time on task in milliseconds (from `unlocked` to `hide_done`).
  int? get timeOnTaskMs {
    MetricEvent? unlockEvent;
    MetricEvent? finishEvent;

    for (final e in _events) {
      if (e.name == 'unlocked' && unlockEvent == null) unlockEvent = e;
      if (e.name == 'hide_done') finishEvent = e;
    }

    if (unlockEvent != null && finishEvent != null) {
      return finishEvent.timestamp.difference(unlockEvent.timestamp).inMilliseconds;
    }

    // Fallback: session start to finish
    if (_sessionStart != null && finishEvent != null) {
      return finishEvent.timestamp.difference(_sessionStart!).inMilliseconds;
    }

    return null;
  }

  /// Whether the user testing flow succeeded:
  /// unlocked -> opened article -> saved offline -> pressed HIDE.
  bool get taskSuccess {
    final names = _events.map((e) => e.name).toSet();
    return names.contains('unlocked') &&
        names.contains('article_open') &&
        names.contains('save_offline') &&
        names.contains('hide_done');
  }

  // ── Export ─────────────────────────────────────────────────────────

  /// Summary dictionary along with full event trajectory.
  Map<String, dynamic> exportMap() {
    return {
      'sessionStart': _sessionStart?.toIso8601String(),
      'metrics': {
        'taskSuccess': taskSuccess,
        'timeOnTaskMs': timeOnTaskMs,
        'hideLatencyMs': hideLatencyMs,
        'tapCount': tapCount,
        'postUnlockTapCount': postUnlockTapCount,
        'pinErrorCount': pinErrorCount,
        'totalEvents': _events.length,
      },
      'events': _events.map((e) => e.toJson()).toList(),
    };
  }

  /// Formatted JSON export for analysis.
  String exportJson({bool pretty = true}) {
    final map = exportMap();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }
}
