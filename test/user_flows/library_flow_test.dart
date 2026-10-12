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
import 'package:cycle_care/screens/education_hub_screen.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_lib_flow_test');
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

  testWidgets(
      'Phase 5 Flow: Hub -> Saved Library topic tile -> OfflineLibraryScreen -> Read Offline -> Panic HIDE',
      (tester) async {
    // 1. Pre-save an article into the store
    await tester.runAsync(() async {
      await SavedArticlesStore.save('iron-rich-foods');
    });

    // 2. Start on Education Hub
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionState>.value(
        value: sessionState,
        child: const MaterialApp(
          home: EducationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Saved Library tile displays "1 Guides Offline"
    expect(find.text('Saved Library'), findsOneWidget);
    expect(find.text('1 Guides Offline'), findsOneWidget);

    // 3. Scroll and tap Saved Library tile
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();

    final savedLibTileFinder = find.text('Saved Library');
    await tester.tap(savedLibTileFinder);
    await tester.pumpAndSettle();

    // Navigated to OfflineLibraryScreen
    expect(find.byType(OfflineLibraryScreen), findsOneWidget);
    expect(find.text('Offline Library'), findsOneWidget);
    expect(find.text('Zero Internet Required'), findsOneWidget);
    expect(find.text('Iron-Rich Foods For Stronger Energy'), findsOneWidget);

    // 4. Tap "Read Offline" pill
    final readOfflineFinder = find.text('Read Offline');
    expect(readOfflineFinder, findsOneWidget);
    await tester.tap(readOfflineFinder);
    await tester.pumpAndSettle();

    // Navigated to ArticleScreen
    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(find.textContaining('Iron-Rich Foods'), findsOneWidget);
    expect(find.text('✓ Saved Offline'), findsOneWidget);

    // 5. Tap panic HIDE button from the article
    final hideFinder = find.byType(HideButton);
    expect(hideFinder, findsOneWidget);
    await tester.tap(hideFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Navigated directly to MainScreen, stack cleared, session locked
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(ArticleScreen), findsNothing);
    expect(find.byType(OfflineLibraryScreen), findsNothing);
    expect(sessionState.unlocked, isFalse);

    await tester.pumpWidget(const SizedBox());
  });
}
