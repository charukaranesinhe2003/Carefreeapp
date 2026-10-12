import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_care/services/metrics_service.dart';

void main() {
  group('MetricsService', () {
    late MetricsService service;

    setUp(() {
      service = MetricsService.instance;
      service.enableForTesting(enabled: true);
      service.reset();
    });

    tearDown(() {
      service.reset();
      service.enableForTesting(enabled: false);
    });

    test('enables and disables metrics recording', () {
      expect(service.isEnabled, isTrue);

      service.record('test_event');
      expect(service.events.length, equals(1));

      service.enableForTesting(enabled: false);
      expect(service.isEnabled, isFalse);

      service.record('ignored_event');
      expect(service.events.length, equals(1));
    });

    test('records events with timestamps and optional payload', () {
      final nowBefore = DateTime.now();
      service.record('pin_key', {'key': '1'});
      final nowAfter = DateTime.now();

      expect(service.events.length, equals(1));
      final event = service.events.first;
      expect(event.name, equals('pin_key'));
      expect(event.data['key'], equals('1'));
      expect(event.timestamp.isAfter(nowBefore.subtract(const Duration(milliseconds: 50))), isTrue);
      expect(event.timestamp.isBefore(nowAfter.add(const Duration(milliseconds: 50))), isTrue);
    });

    test('deduplicates consecutive identical article_open events', () {
      service.record('article_open', {'articleId': 'iron-rich-foods'});
      service.record('article_open', {'articleId': 'iron-rich-foods'});
      service.record('article_open', {'articleId': 'iron-rich-foods'});

      expect(service.events.where((e) => e.name == 'article_open').length, equals(1));

      service.record('article_open', {'articleId': 'water-hydration'});
      expect(service.events.where((e) => e.name == 'article_open').length, equals(2));
    });

    test('computes pinErrorCount and tap counts accurately', () {
      expect(service.pinErrorCount, equals(0));
      expect(service.tapCount, equals(0));
      expect(service.postUnlockTapCount, equals(0));

      // Simulate wrong pin attempt
      service.record('pin_key', {'key': '1'});
      service.record('pin_key', {'key': '2'});
      service.record('pin_error');

      expect(service.pinErrorCount, equals(1));
      expect(service.tapCount, equals(2));
      expect(service.postUnlockTapCount, equals(0));

      // Unlock
      service.record('pin_key', {'key': '1'});
      service.record('pin_key', {'key': '2'});
      service.record('pin_key', {'key': '3'});
      service.record('pin_key', {'key': '4'});
      service.record('unlocked');

      expect(service.tapCount, equals(6));
      expect(service.postUnlockTapCount, equals(0));

      // 4 taps after unlock
      service.record('nav', {'screen': 'CategoryScreen'}); // tap 1
      service.record('article_open', {'articleId': 'iron-rich-foods'}); // not counted as tap
      service.record('nav', {'screen': 'ArticleScreen'}); // tap 2
      service.record('save_offline', {'articleId': 'iron-rich-foods'}); // tap 3
      service.record('hide_tap'); // tap 4
      service.record('hide_done');

      expect(service.tapCount, equals(10));
      expect(service.postUnlockTapCount, equals(4));
    });

    test('computes hideLatencyMs and timeOnTaskMs accurately', () async {
      service.record('unlocked');
      await Future.delayed(const Duration(milliseconds: 20));
      service.record('hide_tap');
      await Future.delayed(const Duration(milliseconds: 15));
      service.record('hide_done');

      final hideLatency = service.hideLatencyMs;
      expect(hideLatency, isNotNull);
      expect(hideLatency!, greaterThanOrEqualTo(10));

      final timeOnTask = service.timeOnTaskMs;
      expect(timeOnTask, isNotNull);
      expect(timeOnTask!, greaterThanOrEqualTo(25));
    });

    test('evaluates taskSuccess correctly', () {
      expect(service.taskSuccess, isFalse);

      service.record('unlocked');
      expect(service.taskSuccess, isFalse);

      service.record('article_open', {'articleId': 'iron-rich-foods'});
      expect(service.taskSuccess, isFalse);

      service.record('save_offline', {'articleId': 'iron-rich-foods'});
      expect(service.taskSuccess, isFalse);

      service.record('hide_done');
      expect(service.taskSuccess, isTrue);
    });

    test('exports JSON structure adhering to protocol specifications', () {
      service.record('lock_shown');
      service.record('pin_key', {'key': '1'});
      service.record('unlocked');
      service.record('article_open', {'articleId': 'iron-rich-foods'});
      service.record('save_offline', {'articleId': 'iron-rich-foods'});
      service.record('hide_tap');
      service.record('hide_done');

      final jsonString = service.exportJson();
      expect(jsonString, isNotEmpty);

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded.containsKey('sessionStart'), isTrue);
      expect(decoded.containsKey('metrics'), isTrue);
      expect(decoded.containsKey('events'), isTrue);

      final metrics = decoded['metrics'] as Map<String, dynamic>;
      expect(metrics['taskSuccess'], isTrue);
      expect(metrics['tapCount'], isNotNull);
      expect(metrics['postUnlockTapCount'], isNotNull);
      expect(metrics['pinErrorCount'], equals(0));

      final events = decoded['events'] as List<dynamic>;
      expect(events.length, equals(7));
    });

    test('startSession clears previous events and sets sessionStart', () {
      service.record('pin_key', {'key': '1'});
      expect(service.events.length, equals(1));

      service.startSession();
      expect(service.events, isEmpty);
      expect(service.sessionStart, isNotNull);
    });
  });
}
