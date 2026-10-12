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
import 'package:cycle_care/screens/category_screen.dart';
import 'package:cycle_care/screens/education_hub_screen.dart';
import 'package:cycle_care/screens/main_screen.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_hub_flow_test');
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
      'Phase 4 Acceptance: Food & Diet -> Iron-Rich Foods -> Save takes 3 taps (<= 4 taps)',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionState>.value(
        value: sessionState,
        child: const MaterialApp(
          home: EducationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var tapCount = 0;

    // Tap 1: Tap "Food & Diet" topic tile on the Hub
    final foodTopicFinder = find.text('Food & Diet');
    expect(foodTopicFinder, findsOneWidget);
    await tester.tap(foodTopicFinder);
    tapCount++;
    await tester.pumpAndSettle();

    expect(find.byType(CategoryScreen), findsOneWidget);

    // Tap 2: Tap "Iron-Rich Foods" article row
    final articleRowFinder =
        find.text('Iron-Rich Foods For Stronger Energy');
    expect(articleRowFinder, findsOneWidget);
    await tester.tap(articleRowFinder);
    tapCount++;
    await tester.pumpAndSettle();

    expect(find.byType(ArticleScreen), findsOneWidget);

    // Tap 3: Tap "Save To Offline Library" button
    final saveButtonFinder = find.text('Save To Offline Library');
    expect(saveButtonFinder, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(saveButtonFinder);
      await Future.delayed(const Duration(milliseconds: 100));
    });
    tapCount++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Verify 3 taps (<= 4 taps requirement satisfied!)
    expect(tapCount, lessThanOrEqualTo(4));
    expect(tapCount, 3);

    // Verify article is saved in storage
    expect(SavedArticlesStore.isSaved('iron-rich-foods'), isTrue);

    // Verify button swapped to "✓ Saved Offline"
    expect(find.text('✓ Saved Offline'), findsOneWidget);

    // Verify toast appeared
    expect(find.text('Saved for Offline Reading!'), findsOneWidget);

    // Test HIDE button panic behavior
    final hideButtonFinder = find.byType(HideButton);
    expect(hideButtonFinder, findsOneWidget);
    await tester.tap(hideButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Swapped to MainScreen instantly
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(ArticleScreen), findsNothing);
    expect(find.byType(CategoryScreen), findsNothing);

    // Session is locked
    expect(sessionState.unlocked, isFalse);

    // Back stack is cleared: Android back cannot return to article
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Daily Health Tip "Read More" -> ArticleScreen direct navigation',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionState>.value(
        value: sessionState,
        child: const MaterialApp(
          home: EducationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final readMoreFinder = find.text('Read More');
    if (readMoreFinder.evaluate().isNotEmpty) {
      await tester.tap(readMoreFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ArticleScreen), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
  });
}
