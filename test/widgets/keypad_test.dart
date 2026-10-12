import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cycle_care/widgets/keypad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Keypad', () {
    testWidgets('fires onDigit for each digit key', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Keypad(
              onDigit: tapped.add,
              onDelete: () {},
            ),
          ),
        ),
      );

      for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
        await tester.tap(find.byKey(ValueKey('keypad-$d')));
      }
      await tester.pump();

      expect(tapped, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
    });

    testWidgets('fires onDelete when delete is pressed', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Keypad(
              onDigit: (_) {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('keypad-delete')));
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgets('does not fire callbacks when disabled', (tester) async {
      var tappedAny = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Keypad(
              enabled: false,
              onDigit: (_) => tappedAny = true,
              onDelete: () => tappedAny = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('keypad-5')));
      await tester.tap(find.byKey(const ValueKey('keypad-delete')));
      await tester.pump();

      expect(tappedAny, isFalse);
    });

    testWidgets('has correct number of keys (10 digits + delete)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Keypad(
              onDigit: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // 10 digit keys + 1 delete key
      for (final d in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        expect(find.byKey(ValueKey('keypad-$d')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('keypad-delete')), findsOneWidget);
    });
  });
}
