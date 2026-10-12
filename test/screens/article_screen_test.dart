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
    tempDir = await Directory.systemTemp.createTemp('hive_article_test');
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

  Widget createSubject(String articleId) {
    return ChangeNotifierProvider<SessionState>.value(
      value: sessionState,
      child: MaterialApp(
        home: ArticleScreen(articleId: articleId),
      ),
    );
  }

  group('ArticleScreen', () {
    testWidgets('renders article content and blocks correctly', (tester) async {
      await tester.pumpWidget(createSubject('iron-rich-foods'));
      await tester.pumpAndSettle();

      // Category label
      expect(find.text('Nutrition Guide'), findsOneWidget);

      // Two-toned title contains the text
      expect(find.textContaining('Iron-Rich Foods'), findsOneWidget);

      // Headings and paragraphs
      expect(find.text('Why iron matters'), findsOneWidget);
      expect(find.textContaining('During your period you lose a little iron'), findsOneWidget);

      // Village tip
      expect(find.textContaining('Village Tip'), findsOneWidget);
      expect(find.textContaining('Squeeze a little lime on leaves'), findsOneWidget);

      // Initial save button state
      expect(find.text('Save To Offline Library'), findsOneWidget);
      expect(find.text('✓ Saved Offline'), findsNothing);
    });

    testWidgets('saving article updates store, button UI, and shows toast', (tester) async {
      await tester.pumpWidget(createSubject('iron-rich-foods'));
      await tester.pumpAndSettle();

      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isFalse);

      // Tap Save inside runAsync so Hive file I/O completes on real event loop
      await tester.runAsync(() async {
        await tester.tap(find.text('Save To Offline Library'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Store is updated
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isTrue);

      // Button UI swapped to "✓ Saved Offline"
      expect(find.text('✓ Saved Offline'), findsOneWidget);
      expect(find.text('Save To Offline Library'), findsNothing);

      // Toast is visible
      expect(find.text('Saved for Offline Reading!'), findsOneWidget);
      expect(find.text('You can read this anytime without Data'), findsOneWidget);

      AppToast.dismiss();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping saved button unsaves article (reversible toggle)', (tester) async {
      await tester.runAsync(() async {
        await SavedArticlesStore.save('iron-rich-foods');
      });

      await tester.pumpWidget(createSubject('iron-rich-foods'));
      await tester.pumpAndSettle();

      // Starts in saved state
      expect(find.text('✓ Saved Offline'), findsOneWidget);

      // Tap to unsave inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.text('✓ Saved Offline'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Store is updated
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isFalse);
      expect(find.text('Save To Offline Library'), findsOneWidget);
      expect(find.text('✓ Saved Offline'), findsNothing);
      expect(find.text('Removed from Offline Library'), findsOneWidget);

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
        builder: (_) => const ArticleScreen(articleId: 'iron-rich-foods'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ArticleScreen), findsOneWidget);
      expect(find.byType(HideButton), findsOneWidget);

      // Tap HIDE
      await tester.tap(find.byType(HideButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Navigated to MainScreen
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(ArticleScreen), findsNothing);

      // Session is locked
      expect(sessionState.unlocked, isFalse);

      // Android back cannot return to ArticleScreen or PreviousScreen (stack was cleared)
      final canPop = nav.canPop();
      expect(canPop, isFalse);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
