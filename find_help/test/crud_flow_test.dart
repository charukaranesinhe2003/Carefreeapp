import 'package:find_help/find_help_host.dart';
import 'package:find_help/models.dart';
import 'package:find_help/screens/details_screen.dart';
import 'package:find_help/screens/directory_screen.dart';
import 'package:find_help/screens/feedback_screen.dart';
import 'package:find_help/screens/filters_screen.dart';
import 'package:find_help/screens/help_screen.dart';
import 'package:find_help/screens/history_screen.dart';
import 'package:find_help/screens/notes_screen.dart';
import 'package:find_help/screens/reminders_screen.dart';
import 'package:find_help/screens/results_screen.dart';
import 'package:find_help/screens/saved_screen.dart';
import 'package:find_help/screens/search_screen.dart';
import 'package:find_help/screens/supplies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every screen opens inside the parent app', (tester) async {
    await _openHost(tester);
    expect(find.textContaining('Find Help'), findsWidgets);
    expect(tester.takeException(), isNull);

    final screens = <Widget>[
      const HelpScreen(),
      const FiltersScreen(),
      const SearchScreen(),
      const HistoryScreen(),
      const SuppliesScreen(),
      const NotesScreen(),
      const RemindersScreen(),
      const DirectoryScreen(),
      const ResultsScreen(showBack: false),
      const SavedScreen(showBack: false),
    ];

    final context = tester.element(find.textContaining('Find Help').first);
    for (final screen in screens) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType} failed to open');
      await _goBack(tester);
      expect(tester.takeException(), isNull);
    }

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    for (final index in [1, 2, 3, 0]) {
      bar.onDestinationSelected!(index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'tab $index failed');
    }

    await tester.tap(find.text('Use My Location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Allow location access'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text("Don't allow"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Search area or place...'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes reminders supplies saved and pharmacies can be created edited and deleted', (tester) async {
    await _openHost(tester);

    await _openScreen(tester, const NotesScreen());
    await _fill<NotesScreen>(tester, 0, 'CRUD Note');
    await _fill<NotesScreen>(tester, 1, 'Test Pharmacy');
    await _fill<NotesScreen>(tester, 2, 'Bring the card');
    await tester.tap(_on<NotesScreen>('Add note'));
    await tester.pump();
    expect(_on<NotesScreen>('CRUD Note'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(_on<NotesScreen>('Edit').first);
    await tester.tap(_on<NotesScreen>('Edit').first);
    await tester.pump();
    await _fill<NotesScreen>(tester, 0, 'CRUD Note Edited');
    await tester.ensureVisible(_on<NotesScreen>('Save note'));
    await tester.tap(_on<NotesScreen>('Save note'));
    await tester.pump();
    expect(find.text('CRUD Note Edited'), findsWidgets);
    expect(find.text('CRUD Note'), findsNothing);

    await tester.ensureVisible(_on<NotesScreen>('Delete').first);
    await tester.tap(_on<NotesScreen>('Delete').first);
    await tester.pump();
    await tester.tap(_on<NotesScreen>('Delete').first);
    await tester.pump();
    expect(find.text('CRUD Note Edited'), findsNothing);
    expect(tester.takeException(), isNull);
    await _goBack(tester);

    await _openScreen(tester, const RemindersScreen());
    await _fill<RemindersScreen>(tester, 0, 'CRUD Reminder');
    await tester.ensureVisible(_on<RemindersScreen>('Add reminder'));
    await tester.tap(_on<RemindersScreen>('Add reminder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CRUD Reminder'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(_on<RemindersScreen>('Edit').first);
    await tester.tap(_on<RemindersScreen>('Edit').first);
    await tester.pump();
    await _fill<RemindersScreen>(tester, 0, 'CRUD Reminder Edited');
    await tester.ensureVisible(_on<RemindersScreen>('Save reminder'));
    await tester.tap(_on<RemindersScreen>('Save reminder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('CRUD Reminder Edited'), findsWidgets);

    await tester.ensureVisible(_on<RemindersScreen>('Delete').first);
    await tester.tap(_on<RemindersScreen>('Delete').first);
    await tester.pump();
    await tester.tap(_on<RemindersScreen>('Delete').first);
    await tester.pump();
    expect(find.text('CRUD Reminder Edited'), findsNothing);
    expect(tester.takeException(), isNull);
    await _goBack(tester);

    await _openScreen(tester, const SuppliesScreen());
    await tester.tap(_on<SuppliesScreen>('Add item'));
    await tester.pump();
    await _fill<SuppliesScreen>(tester, 0, 'CRUD Pads');
    await _fill<SuppliesScreen>(tester, 1, '2 packs');
    await _tapLabel<SuppliesScreen>(tester, 'Add to supply list');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('CRUD Pads').hitTestable(),
      220,
      scrollable: find.descendant(of: find.byType(SuppliesScreen), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('CRUD Pads'), findsWidgets);
    expect(tester.takeException(), isNull);

    final padsCard = find.ancestor(of: find.text('CRUD Pads'), matching: find.byType(Column)).at(1);
    await tester.ensureVisible(find.descendant(of: padsCard, matching: find.text('Edit')));
    await tester.tap(find.descendant(of: padsCard, matching: find.text('Edit')));
    await tester.pump();
    await tester.drag(
      find.descendant(of: find.byType(SuppliesScreen), matching: find.byType(Scrollable)).first,
      const Offset(0, 900),
    );
    await tester.pump();
    await _fill<SuppliesScreen>(tester, 0, 'CRUD Pads Edited');
    await _tapLabel<SuppliesScreen>(tester, 'Save changes');
    await tester.pump();
    expect(find.text('CRUD Pads Edited'), findsWidgets);

    final editedPads = find.ancestor(of: find.text('CRUD Pads Edited'), matching: find.byType(Column)).at(1);
    await tester.tap(find.descendant(of: editedPads, matching: find.text('Delete')));
    await tester.pump();
    await tester.tap(find.descendant(of: editedPads, matching: find.text('Delete')));
    await tester.pump();
    expect(find.text('CRUD Pads Edited'), findsNothing);
    expect(tester.takeException(), isNull);
    await _goBack(tester);

    await _openScreen(tester, const DirectoryScreen());
    await tester.tap(_on<DirectoryScreen>('Add'));
    await tester.pump();
    await _fill<DirectoryScreen>(tester, 0, 'CRUD Pharmacy');
    await _fill<DirectoryScreen>(tester, 1, 'Kottawa');
    await tester.ensureVisible(_on<DirectoryScreen>('Save pharmacy'));
    await tester.tap(_on<DirectoryScreen>('Save pharmacy'));
    await tester.pump();
    expect(find.text('CRUD Pharmacy'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(_on<DirectoryScreen>('Edit').first);
    await tester.tap(_on<DirectoryScreen>('Edit').first);
    await tester.pump();
    await _fill<DirectoryScreen>(tester, 0, 'CRUD Pharmacy Edited');
    await tester.ensureVisible(_on<DirectoryScreen>('Update pharmacy'));
    await tester.tap(_on<DirectoryScreen>('Update pharmacy'));
    await tester.pump();
    expect(find.text('CRUD Pharmacy Edited'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
    await _tapLabel<DirectoryScreen>(tester, 'Delete');
    expect(find.text('CRUD Pharmacy Edited'), findsNothing);
    expect(tester.takeException(), isNull);
    await _goBack(tester);

    await _openScreen(tester, const SavedScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.tap(_on<SavedScreen>('Add place'));
    await tester.pump();
    await _fill<SavedScreen>(tester, 0, 'CRUD Place');
    await _fill<SavedScreen>(tester, 1, 'Maharagama');
    await _tapLabel<SavedScreen>(tester, 'Add to saved places');
    await tester.pump();
    expect(find.text('CRUD Place'), findsWidgets);
    expect(tester.takeException(), isNull);

    final editPlace = find.descendant(of: find.byType(SavedScreen), matching: find.byIcon(Icons.edit_rounded));
    await tester.ensureVisible(editPlace.first);
    await tester.tap(editPlace.first);
    await tester.pump();
    await tester.drag(
      find.descendant(of: find.byType(SavedScreen), matching: find.byType(Scrollable)).first,
      const Offset(0, 900),
    );
    await tester.pump();
    await _fill<SavedScreen>(tester, 0, 'CRUD Place Edited');
    await _tapLabel<SavedScreen>(tester, 'Save changes');
    expect(find.text('CRUD Place Edited'), findsWidgets);

    final deletePlace = find.descendant(of: find.byType(SavedScreen), matching: find.byIcon(Icons.delete_outline_rounded));
    await tester.ensureVisible(deletePlace.first);
    await tester.tap(deletePlace.first);
    await tester.pump();
    await tester.tap(_on<SavedScreen>('Remove').hitTestable().first);
    await tester.pump();
    expect(find.text('CRUD Place Edited'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('place details history and feedback open and update', (tester) async {
    await _openHost(tester);
    await _openScreen(tester, DetailsScreen(place: places.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('FACILITY PROFILE'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Rate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('How did it go?'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Yes, this helped'));
    await tester.pump();
    await tester.ensureVisible(find.text('Submit feedback'));
    await tester.tap(find.text('Submit feedback'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('Delete saved feedback').hitTestable(),
      200,
      scrollable: _verticalList().last,
    );
    expect(find.text('Delete saved feedback'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Delete saved feedback'));
    await tester.pump();
    expect(find.text('Submit feedback'), findsWidgets);
    expect(tester.takeException(), isNull);

    await _goBack(tester);
    await _goBack(tester);

    await _openScreen(tester, const HistoryScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Visit history'), findsWidgets);
    expect(find.text('Remove'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Remove').first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openHost(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(360, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FindHelpHost()),
                );
              },
              child: const Text('open-find-help'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-find-help'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

Finder _verticalList() {
  return find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

Future<void> _goBack(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).last).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Finder _on<T extends Widget>(String text) {
  return find.descendant(of: find.byType(T), matching: find.text(text));
}

Future<void> _tapLabel<T extends Widget>(WidgetTester tester, String label) async {
  final target = _on<T>(label).hitTestable();
  final list = find.descendant(of: find.byType(T), matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(target, 160, scrollable: list.first);
  await tester.tap(target.first);
  await tester.pump();
}

Future<void> _fill<T extends Widget>(WidgetTester tester, int index, String value) async {
  final field = find.descendant(of: find.byType(T), matching: find.byType(TextField)).at(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _openScreen(WidgetTester tester, Widget screen) async {
  tester.state<NavigatorState>(find.byType(Navigator).last).push(
    MaterialPageRoute<void>(builder: (_) => screen),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull, reason: '${screen.runtimeType} did not open');
}
