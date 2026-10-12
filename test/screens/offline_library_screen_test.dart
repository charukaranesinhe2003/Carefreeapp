import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:cycle_care/models/cycle_entry.dart';
import 'package:cycle_care/models/saved_article.dart';
import 'package:cycle_care/models/starred_tip.dart';
import 'package:cycle_care/models/daily_log.dart';
import 'package:cycle_care/screens/article_screen.dart';
import 'package:cycle_care/screens/main_screen.dart';
import 'package:cycle_care/screens/offline_library_screen.dart';
import 'package:cycle_care/services/pin_service.dart';
import 'package:cycle_care/services/saved_articles_store.dart';
import 'package:cycle_care/services/session_state.dart';
import 'package:cycle_care/widgets/app_toast.dart';
import 'package:cycle_care/widgets/hide_button.dart';

class _FakePinService implements PinService {
  @override
  Future<bool> isSet() async => true;
  @override
  Future<bool> verify(String pin) async => true;
  @override
  Future<void> set(String pin) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionState sessionState;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_library_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CycleEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedArticleAdapter());
    }
    await Hive.openBox<CycleEntry>('cycle_entries');
    await Hive.openBox<SavedArticle>(SavedArticlesStore.boxName);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyLogAdapter());
    }
    await Hive.openBox<DailyLog>('daily_logs');
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(StarredTipAdapter());
    }
    await Hive.openBox<StarredTip>('starred_tips');
    await Hive.openBox<dynamic>('settings');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppToast.reset();
    await Hive.box<CycleEntry>('cycle_entries').clear();
    await Hive.box<SavedArticle>(SavedArticlesStore.boxName).clear();
    await Hive.box<dynamic>('settings').clear();
    sessionState = SessionState(pinService: _FakePinService());
    await sessionState.tryUnlock('1234');
  });

  tearDown(() {
    AppToast.reset();
    sessionState.dispose();
  });

  Widget createSubject() {
    return ChangeNotifierProvider<SessionState>.value(
      value: sessionState,
      child: const MaterialApp(
        home: OfflineLibraryScreen(),
      ),
    );
  }

  group('OfflineLibraryScreen', () {
    testWidgets('shows empty state when no articles are saved', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Top bar title
      expect(find.text('Offline Library'), findsOneWidget);

      // Green-tinted banner
      expect(find.text('Zero Internet Required'), findsOneWidget);
      expect(find.text('Read without data or village signal issues'), findsOneWidget);

      // Empty state content
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('Browse topics'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders saved articles sorted newest first with Read Offline pill', (tester) async {
      await tester.runAsync(() async {
        final olderDate = DateTime(2026, 9, 10);
        final newerDate = DateTime(2026, 9, 20);
        await SavedArticlesStore.save('water-hydration', at: olderDate);
        await SavedArticlesStore.save('iron-rich-foods', at: newerDate);
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Both articles rendered
      expect(find.text('Iron-Rich Foods For Stronger Energy'), findsOneWidget);
      expect(find.text('Water & Hydration'), findsOneWidget);

      // Read Offline pills rendered
      expect(find.text('Read Offline'), findsNWidgets(2));

      // Meta info with formatted date
      expect(find.textContaining('Saved on 20 Sep'), findsOneWidget);
      expect(find.textContaining('Saved on 10 Sep'), findsOneWidget);

      // Empty state is not shown
      expect(find.text('Nothing saved yet'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping Read Offline navigates to ArticleScreen', (tester) async {
      await tester.runAsync(() async {
        await SavedArticlesStore.save('iron-rich-foods');
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap Read Offline pill
      await tester.tap(find.text('Read Offline'));
      await tester.pumpAndSettle();

      // ArticleScreen is displayed
      expect(find.byType(ArticleScreen), findsOneWidget);
      expect(find.textContaining('Iron-Rich Foods'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping remove button unsaves article and reactively updates UI', (tester) async {
      await tester.runAsync(() async {
        await SavedArticlesStore.save('iron-rich-foods');
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Iron-Rich Foods For Stronger Energy'), findsOneWidget);
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isTrue);

      // Tap unsave button inside runAsync
      final removeButtonFinder = find.byIcon(Icons.bookmark_remove_outlined);
      expect(removeButtonFinder, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(removeButtonFinder);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Store updated
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isFalse);

      // Toast appeared
      expect(find.text('Removed from Offline Library'), findsOneWidget);

      // UI transitioned to empty state reactively
      expect(find.text('Nothing saved yet'), findsOneWidget);

      AppToast.dismiss();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping HIDE button clears stack to MainScreen and locks session', (tester) async {
      expect(sessionState.unlocked, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<SessionState>.value(
          value: sessionState,
          child: const MaterialApp(
            home: Scaffold(body: Text('PreviousScreen')),
          ),
        ),
      );

      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute(
        builder: (_) => const OfflineLibraryScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OfflineLibraryScreen), findsOneWidget);
      expect(find.byType(HideButton), findsOneWidget);

      // Tap HIDE button
      await tester.tap(find.byType(HideButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Swapped to MainScreen
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(OfflineLibraryScreen), findsNothing);

      // Session is locked
      expect(sessionState.unlocked, isFalse);

      // Android back cannot reopen library
      expect(nav.canPop(), isFalse);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
