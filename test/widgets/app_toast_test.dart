import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cycle_care/widgets/app_toast.dart';
import 'package:cycle_care/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppToast', () {
    testWidgets('shows message and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'Test Title',
                    subtitle: 'Test Subtitle',
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);

      // Dismiss to avoid pending-timer assertion.
      AppToast.dismiss();
    });

    testWidgets('auto-dismisses after duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'Auto Dismiss',
                    duration: const Duration(seconds: 2),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Auto Dismiss'), findsOneWidget);

      // Advance past the duration so the timer fires.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Auto Dismiss'), findsNothing);
    });

    testWidgets('dismiss() removes the toast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppToast.show(context, message: 'Will Dismiss');
                    },
                    child: const Text('Show'),
                  ),
                  ElevatedButton(
                    onPressed: AppToast.dismiss,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Will Dismiss'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Will Dismiss'), findsNothing);
      // Timer was cancelled by dismiss(), no pending timer.
    });

    testWidgets('uses maroon background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(context, message: 'Styled');
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.text('Styled'),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppTheme.maroon);

      // Dismiss to avoid pending-timer assertion.
      AppToast.dismiss();
    });
  });
}
