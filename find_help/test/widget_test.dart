import 'package:find_help/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home explains how to start a search', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FindHelpApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Find Help'), findsOneWidget);
    expect(find.text('Use My Location'), findsOneWidget);
    expect(find.text('LIVE GPS'), findsOneWidget);
  });

  testWidgets('location screen shows allow and manual search', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FindHelpApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('Use My Location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Allow location access'), findsOneWidget);
    expect(find.text("Don't allow"), findsOneWidget);
    final allow = tester.getRect(find.text('Allow location access'));
    expect(allow.height, greaterThan(20));
    expect(allow.top, greaterThan(100));
    expect(allow.bottom, lessThan(800));
  });
}