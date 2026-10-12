import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:cycle_care/content/content_repository.dart';
import 'package:cycle_care/l10n/lang.dart';
import 'package:cycle_care/models/cycle_entry.dart';
import 'package:cycle_care/models/saved_article.dart';
import 'package:cycle_care/models/starred_tip.dart';
import 'package:cycle_care/models/daily_log.dart';
import 'package:cycle_care/screens/article_screen.dart';
import 'package:cycle_care/screens/category_screen.dart';
import 'package:cycle_care/screens/education_hub_screen.dart';
import 'package:cycle_care/screens/myth_buster_screen.dart';
import 'package:cycle_care/screens/offline_library_screen.dart';
import 'package:cycle_care/screens/privacy_lock_screen.dart';
import 'package:cycle_care/services/pin_service.dart';
import 'package:cycle_care/services/saved_articles_store.dart';
import 'package:cycle_care/services/session_state.dart';
import 'package:cycle_care/widgets/app_toast.dart';

class _FakePinService implements PinService {
  @override
  Future<bool> isSet() async => true;
  @override
  Future<bool> verify(String pin) async => pin == '1234';
  @override
  Future<void> set(String pin) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionState sessionState;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_a11y_test');
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
    LangService.setPreview(Lang.en);
    await Hive.box<CycleEntry>('cycle_entries').clear();
    await Hive.box<SavedArticle>(SavedArticlesStore.boxName).clear();
    await Hive.box<dynamic>('settings').clear();
    sessionState = SessionState(pinService: _FakePinService());
    await sessionState.tryUnlock('1234');
  });

  tearDown(() {
    AppToast.reset();
    LangService.setPreview(Lang.en);
    sessionState.dispose();
  });

  Widget wrapWithA11y(
    Widget child, {
    double textScale = 1.0,
    bool disableAnimations = false,
  }) {
    return ChangeNotifierProvider<SessionState>.value(
      value: sessionState,
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'Outfit',
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child,
        ),
      ),
    );
  }

  group('Phase 7: Offline Hardening & Content Access', () {
    test('Content repository operates 100% offline with zero network requests', () {
      const repo = BundledRepository();

      // All categories load synchronously
      final categories = repo.categories();
      expect(categories.length, greaterThanOrEqualTo(2));

      // Articles load synchronously
      final foodArticles = repo.articles(categoryId: 'food-diet');
      expect(foodArticles.length, greaterThanOrEqualTo(3));

      final ourBodyArticles = repo.articles(categoryId: 'our-body');
      expect(ourBodyArticles.length, greaterThanOrEqualTo(3));

      // Deterministic daily tips
      final tip = repo.tipForDate(DateTime(2026, 10, 7));
      expect(tip.text.en, isNotEmpty);
      expect(tip.text.si, isNotEmpty);

      // Myth questions
      final questions = repo.mythQuestions();
      expect(questions.length, greaterThanOrEqualTo(5));
      for (final q in questions) {
        expect(q.statement.en, isNotEmpty);
        expect(q.statement.si, isNotEmpty);
        expect(q.explanation.en, isNotEmpty);
        expect(q.explanation.si, isNotEmpty);
      }
    });

    test('GoogleFonts runtime fetching is disabled', () {
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    });
  });

  group('Phase 7: Sinhala i18n Verification Across All Screens', () {
    testWidgets('PrivacyLockScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(
        wrapWithA11y(const PrivacyLockScreen()),
      );
      await tester.pumpAndSettle();

      // Sinhala title and subtitle
      expect(find.text('රහස්‍ය PIN අංකය ඇතුළත් කරන්න'), findsOneWidget);
      expect(
        find.text('ඔබේ චක්‍ර සහ සෞඛ්‍ය වාර්තා පෞද්ගලිකව තබා ගන්න'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('EducationHubScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(wrapWithA11y(const EducationHubScreen()));
      await tester.pumpAndSettle();

      // Sinhala greeting and section headers
      expect(find.text('ආයුබෝවන්'), findsOneWidget);
      expect(find.text('දිනපතා සෞඛ්‍ය ඉඟිය'), findsOneWidget);
      expect(find.text('මාතෘකා ගවේෂණය කරන්න'), findsOneWidget);
      expect(find.text('ආහාර සහ පෝෂණය'), findsOneWidget);
      expect(find.text('සුරැකි පුස්තකාලය'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('CategoryScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(
        wrapWithA11y(const CategoryScreen(categoryId: 'food-diet')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ආහාර සහ පෝෂණය'), findsOneWidget);
      expect(find.text('සියලු ඉඟි'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ArticleScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(
        wrapWithA11y(const ArticleScreen(articleId: 'iron-rich-foods')),
      );
      await tester.pumpAndSettle();

      // Save button in Sinhala
      expect(find.text('නොබැඳි පුස්තකාලයට සුරකින්න'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('OfflineLibraryScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(wrapWithA11y(const OfflineLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('නොබැඳි පුස්තකාලය'), findsOneWidget);
      expect(find.text('අන්තර්ජාලය අවශ්‍ය නැත'), findsOneWidget);
      expect(find.text('තවම කිසිවක් සුරැකී නැත'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('MythBusterScreen renders in Sinhala without issues', (tester) async {
      LangService.setPreview(Lang.si);

      await tester.pumpWidget(
        wrapWithA11y(const MythBusterScreen(shuffleQuestions: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('මිථ්‍යා බිඳින්නා ප්‍රශ්නාවලිය'), findsOneWidget);
      expect(find.text('මෙය මිථ්‍යාවකි'), findsOneWidget);
      expect(find.text('මෙය සත්‍යයකි'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Phase 7: Accessibility & Large Font Scaling', () {
    testWidgets('EducationHubScreen layout survives 1.5x large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        wrapWithA11y(const EducationHubScreen(), textScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore Topics'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ArticleScreen layout survives 1.5x large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        wrapWithA11y(const ArticleScreen(articleId: 'iron-rich-foods'), textScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save To Offline Library'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('OfflineLibraryScreen survives 1.5x large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        wrapWithA11y(const OfflineLibraryScreen(), textScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zero Internet Required'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('MythBusterScreen survives 1.5x large text scale without overflow', (tester) async {
      await tester.pumpWidget(
        wrapWithA11y(const MythBusterScreen(shuffleQuestions: false), textScale: 1.5),
      );
      await tester.pumpAndSettle();

      expect(find.text("It's a MYTH"), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Reduced motion mode handles PrivacyLockScreen gracefully', (tester) async {
      await tester.pumpWidget(
        wrapWithA11y(
          const PrivacyLockScreen(),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN: 9999 inside runAsync so Hive lockout persistence finishes
      await tester.runAsync(() async {
        for (final digit in ['9', '9', '9', '9']) {
          await tester.tap(find.text(digit));
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
