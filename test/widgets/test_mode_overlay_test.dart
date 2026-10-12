import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_care/services/metrics_service.dart';
import 'package:cycle_care/widgets/test_mode_overlay.dart';

void main() {
  group('TestModeOverlay', () {
    setUp(() {
      MetricsService.instance.enableForTesting(enabled: false);
      MetricsService.instance.reset();
    });

    tearDown(() {
      MetricsService.instance.reset();
      MetricsService.instance.enableForTesting(enabled: false);
    });

    testWidgets('renders only child when test mode is disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestModeOverlay(
            child: Scaffold(
              body: Text('App Content'),
            ),
          ),
        ),
      );

      expect(find.text('App Content'), findsOneWidget);
      expect(find.textContaining('TEST •'), findsNothing);
    });

    testWidgets('renders floating test badge when test mode is enabled', (tester) async {
      MetricsService.instance.enableForTesting(enabled: true);

      await tester.pumpWidget(
        const MaterialApp(
          home: TestModeOverlay(
            child: Scaffold(
              body: Text('App Content'),
            ),
          ),
        ),
      );

      expect(find.text('App Content'), findsOneWidget);
      expect(find.text('TEST • 0 taps'), findsOneWidget);

      // Simulate a tap event
      MetricsService.instance.record('unlocked');
      MetricsService.instance.record('nav');
      await tester.pump();

      expect(find.text('TEST • 1 taps'), findsOneWidget);
    });

    testWidgets('tapping badge opens metrics dialog and shows details', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      MetricsService.instance.enableForTesting(enabled: true);
      MetricsService.instance.record('pin_error');
      MetricsService.instance.record('unlocked');
      MetricsService.instance.record('nav');
      MetricsService.instance.record('article_open', {'articleId': 'iron-rich-foods'});
      MetricsService.instance.record('save_offline', {'articleId': 'iron-rich-foods'});
      MetricsService.instance.record('hide_tap');
      MetricsService.instance.record('hide_done');

      await tester.pumpWidget(
        const MaterialApp(
          home: TestModeOverlay(
            child: Scaffold(
              body: Text('App Content'),
            ),
          ),
        ),
      );

      // Tap the badge
      await tester.tap(find.textContaining('TEST •'));
      await tester.pumpAndSettle();

      // Verify modal contents
      expect(find.text('User Testing Metrics'), findsOneWidget);
      expect(find.text('Taps (Post-Unlock)'), findsOneWidget);
      expect(find.text('PIN Errors'), findsOneWidget);
      expect(find.text('Task Completed Successfully'), findsOneWidget);
      expect(find.text('Reset Session'), findsOneWidget);
      expect(find.text('Export JSON'), findsOneWidget);

      // Tap Reset Session
      await tester.tap(find.text('Reset Session'));
      await tester.pumpAndSettle();

      // Modal closed, tap count reset
      expect(find.text('User Testing Metrics'), findsNothing);
      expect(find.text('TEST • 0 taps'), findsOneWidget);
    });

    testWidgets('badge is draggable across the screen', (tester) async {
      MetricsService.instance.enableForTesting(enabled: true);

      await tester.pumpWidget(
        const MaterialApp(
          home: TestModeOverlay(
            child: Scaffold(
              body: Text('App Content'),
            ),
          ),
        ),
      );

      final badgeFinder = find.byKey(const Key('test_mode_drag_detector'));
      final initialPosition = tester.getTopLeft(badgeFinder);

      // Drag badge
      await tester.drag(badgeFinder, const Offset(100, 150));
      await tester.pumpAndSettle();

      final newPosition = tester.getTopLeft(badgeFinder);
      expect(newPosition.dx, greaterThan(initialPosition.dx));
      expect(newPosition.dy, greaterThan(initialPosition.dy));
    });
  });
}
