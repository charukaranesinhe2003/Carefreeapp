import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:cycle_care/models/saved_article.dart';
import 'package:cycle_care/screens/article_screen.dart';
import 'package:cycle_care/screens/category_screen.dart';
import 'package:cycle_care/services/saved_articles_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_category_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedArticleAdapter());
    }
    await Hive.openBox<SavedArticle>(SavedArticlesStore.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.box<SavedArticle>(SavedArticlesStore.boxName).clear();
  });

  group('CategoryScreen', () {
    testWidgets('renders category title, filter chips and articles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(categoryId: 'food-diet'),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Food & Diet'), findsOneWidget);

      // Filter chips
      expect(find.text('All Tips'), findsOneWidget);
      expect(find.text('Cramp Relief'), findsOneWidget);
      expect(find.text('Vitamins'), findsOneWidget);

      // Articles
      expect(find.text('Iron-Rich Foods For Stronger Energy'), findsOneWidget);
      expect(find.text('Water & Hydration'), findsOneWidget);
      expect(find.text('Foods To Avoid'), findsOneWidget);
    });

    testWidgets('filtering by chip narrows the articles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(categoryId: 'food-diet'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Vitamins chip
      await tester.tap(find.text('Vitamins'));
      await tester.pumpAndSettle();

      // Only Iron-Rich Foods should be visible
      expect(find.text('Iron-Rich Foods For Stronger Energy'), findsOneWidget);
      expect(find.text('Water & Hydration'), findsNothing);
      expect(find.text('Foods To Avoid'), findsNothing);
    });

    testWidgets('tapping an article row navigates to ArticleScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoryScreen(categoryId: 'food-diet'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Iron-Rich Foods
      await tester.tap(find.text('Iron-Rich Foods For Stronger Energy'));
      await tester.pumpAndSettle();

      // ArticleScreen is displayed
      expect(find.byType(ArticleScreen), findsOneWidget);
      expect(find.text('Nutrition Guide'), findsOneWidget);
      expect(find.text('Save To Offline Library'), findsOneWidget);
    });
  });
}
