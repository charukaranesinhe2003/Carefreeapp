import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_care/widgets/hide_button.dart';

void main() {
  group('HideButton', () {
    testWidgets('renders HIDE label and close icon', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HideButton(
              onHide: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('HIDE'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byType(HideButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders custom label and executes callback', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HideButton(
              label: 'PANIC',
              onHide: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('PANIC'), findsOneWidget);
      await tester.tap(find.byType(HideButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('has accessible semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HideButton(
              label: 'Hide Now',
              onHide: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(HideButton));
      expect(semantics.label, 'Hide Now');
    });
  });
}
