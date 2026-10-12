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
import 'package:cycle_care/screens/education_hub_screen.dart';
import 'package:cycle_care/screens/main_screen.dart';
import 'package:cycle_care/screens/myth_buster_screen.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_quiz_flow_test');
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
      'Phase 6 Flow: Hub -> Myth Buster tile -> MythBusterScreen -> Panic HIDE',
      (tester) async {
    // 1. Start on Education Hub
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionState>.value(
        value: sessionState,
        child: const MaterialApp(
          home: EducationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Drag to reveal Myth Buster tile
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();

    // Verify Myth Buster tile
    final mythTileFinder = find.text('Myth Buster');
    expect(mythTileFinder, findsOneWidget);
    expect(find.text('Fun Quiz Game'), findsOneWidget);

    // 3. Tap Myth Buster tile
    await tester.tap(mythTileFinder);
    await tester.pumpAndSettle();

    // Navigated to MythBusterScreen
    expect(find.byType(MythBusterScreen), findsOneWidget);
    expect(find.text('Myth Buster Quiz'), findsOneWidget);
    expect(find.text('QUESTION 1 OF 5'), findsOneWidget);

    // 4. Tap panic HIDE button from the quiz
    final hideFinder = find.byType(HideButton);
    expect(hideFinder, findsOneWidget);
    await tester.tap(hideFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Navigated directly to MainScreen, stack cleared, session locked
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(MythBusterScreen), findsNothing);
    expect(sessionState.unlocked, isFalse);

    await tester.pumpWidget(const SizedBox());
  });
}
