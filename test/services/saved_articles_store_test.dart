import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cycle_care/models/saved_article.dart';
import 'package:cycle_care/services/saved_articles_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_saved_test');
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
    await Hive.box<SavedArticle>(SavedArticlesStore.boxName).clear();
  });

  group('SavedArticlesStore', () {
    test('initially empty', () {
      expect(SavedArticlesStore.count, 0);
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isFalse);
      expect(SavedArticlesStore.all(), isEmpty);
    });

    test('save adds article to store', () async {
      await SavedArticlesStore.save('iron-rich-foods');

      expect(SavedArticlesStore.count, 1);
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isTrue);
      final items = SavedArticlesStore.all();
      expect(items.length, 1);
      expect(items.first.articleId, 'iron-rich-foods');
    });

    test('remove removes article from store', () async {
      await SavedArticlesStore.save('iron-rich-foods');
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isTrue);

      await SavedArticlesStore.remove('iron-rich-foods');
      expect(SavedArticlesStore.count, 0);
      expect(SavedArticlesStore.isSaved('iron-rich-foods'), isFalse);
    });

    test('toggle saves when not saved, removes when saved (reversible)', () async {
      // 1. Toggle when not saved -> saves it
      final saved1 = await SavedArticlesStore.toggle('water-hydration');
      expect(saved1, isTrue);
      expect(SavedArticlesStore.isSaved('water-hydration'), isTrue);

      // 2. Toggle when already saved -> removes it
      final saved2 = await SavedArticlesStore.toggle('water-hydration');
      expect(saved2, isFalse);
      expect(SavedArticlesStore.isSaved('water-hydration'), isFalse);
    });

    test('all() sorts newest saved first', () async {
      final earlier = DateTime(2026, 9, 10);
      final later = DateTime(2026, 9, 20);

      await SavedArticlesStore.save('art-1', at: earlier);
      await SavedArticlesStore.save('art-2', at: later);

      final all = SavedArticlesStore.all();
      expect(all.length, 2);
      expect(all.first.articleId, 'art-2');
      expect(all.last.articleId, 'art-1');
    });
  });
}
