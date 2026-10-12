import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_article.dart';

/// Storage for the Offline Library (Member 3). Only touches the
/// `saved_articles` box; never the cycle entries or Member 1's settings.
///
/// Call [init] after Hive has been initialised (see `main.dart`).
class SavedArticlesStore {
  SavedArticlesStore._();

  static const String boxName = 'saved_articles';
  static const int _adapterTypeId = 1;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(_adapterTypeId)) {
      Hive.registerAdapter(SavedArticleAdapter());
    }
    await Hive.openBox<SavedArticle>(boxName);
  }

  static Box<SavedArticle> get _box => Hive.box<SavedArticle>(boxName);

  /// Rebuild UI (for example the "{n} Guides Offline" count) when this changes.
  static ValueListenable<Box<SavedArticle>> get listenable => _box.listenable();

  static int get count => _box.length;

  static bool isSaved(String articleId) => _box.containsKey(articleId);

  static Future<void> save(String articleId, {DateTime? at}) async {
    await _box.put(
      articleId,
      SavedArticle(articleId: articleId, savedAt: at ?? DateTime.now()),
    );
  }

  static Future<void> remove(String articleId) => _box.delete(articleId);

  /// Saves if not saved, removes if saved. Returns true if it is saved afterwards.
  static Future<bool> toggle(String articleId) async {
    if (isSaved(articleId)) {
      await remove(articleId);
      return false;
    }
    await save(articleId);
    return true;
  }

  /// Newest first.
  static List<SavedArticle> all() {
    final items = _box.values.toList();
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }
}
