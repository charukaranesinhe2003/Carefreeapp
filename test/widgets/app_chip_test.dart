import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cycle_care/widgets/app_chip.dart';
import 'package:cycle_care/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(label: 'All Tips'),
          ),
        ),
      );

      expect(find.text('All Tips'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppChip(
              label: 'Vitamins',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppChip));
      expect(tapped, isTrue);
    });

    testWidgets('shows primary background when selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(label: 'Selected', selected: true),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.text('Selected'),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppTheme.primaryColor);
    });

    testWidgets('shows card background when not selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(label: 'Unselected', selected: false),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.text('Unselected'),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppTheme.cardColor);
    });

    testWidgets('status chip uses success colour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(label: 'Saved', kind: AppChipKind.status),
          ),
        ),
      );

      // The success chip background is semi-transparent success.
      final material = tester.widget<Material>(
        find.ancestor(
          of: find.text('Saved'),
          matching: find.byType(Material),
        ).first,
      );
      // The shape border should use success colour.
      final border = material.shape as StadiumBorder;
      expect(border.side.color, AppTheme.success);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppChip(label: 'With Icon', icon: Icons.check),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
