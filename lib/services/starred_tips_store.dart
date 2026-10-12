import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/starred_tip.dart';

/// Storage for the Daily Tips Bookmark Queue (Member 3).
/// Provides full CRUD: Create, Read, Update (edit category), Delete.
///
/// Call [init] after Hive has been initialised (see `main.dart`).
class StarredTipsStore {
  StarredTipsStore._();

  static const String boxName = 'starred_tips';
  static const int _adapterTypeId = 3;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(_adapterTypeId)) {
      Hive.registerAdapter(StarredTipAdapter());
    }
    await Hive.openBox<StarredTip>(boxName);
  }

  static Box<StarredTip> get _box => Hive.box<StarredTip>(boxName);

  /// Rebuild UI when starred tips change.
  static ValueListenable<Box<StarredTip>> get listenable => _box.listenable();

  static int get count => _box.length;

  // ── CREATE ─────────────────────────────────────────────────────────

  /// Stars a tip. If already starred, does nothing.
  static Future<void> star({
    required String tipId,
    required String contentEn,
    required String contentSi,
    String category = 'daily_tip',
    DateTime? at,
  }) async {
    if (isStarred(tipId)) return;
    await _box.put(
      tipId,
      StarredTip(
        tipId: tipId,
        contentEn: contentEn,
        contentSi: contentSi,
        category: category,
        starredAt: at ?? DateTime.now(),
      ),
    );
  }

  // ── READ ───────────────────────────────────────────────────────────

  static bool isStarred(String tipId) => _box.containsKey(tipId);

  /// Returns all starred tips sorted by most recently starred first.
  static List<StarredTip> all() {
    final items = _box.values.toList();
    items.sort((a, b) => b.starredAt.compareTo(a.starredAt));
    return items;
  }

  /// Returns starred tips filtered by category, newest first.
  static List<StarredTip> byCategory(String category) {
    return all().where((tip) => tip.category == category).toList();
  }

  /// Returns a single starred tip by its id, or null.
  static StarredTip? get(String tipId) => _box.get(tipId);

  // ── UPDATE ─────────────────────────────────────────────────────────

  /// Updates the category label for an existing starred tip.
  static Future<void> updateCategory(String tipId, String newCategory) async {
    final tip = _box.get(tipId);
    if (tip == null) return;
    tip.category = newCategory;
    await tip.save();
  }

  // ── DELETE ─────────────────────────────────────────────────────────

  /// Removes a starred tip.
  static Future<void> unstar(String tipId) => _box.delete(tipId);

  /// Stars if not starred, unstars if starred. Returns true if starred
  /// afterwards.
  static Future<bool> toggle({
    required String tipId,
    required String contentEn,
    required String contentSi,
    String category = 'daily_tip',
  }) async {
    if (isStarred(tipId)) {
      await unstar(tipId);
      return false;
    }
    await star(
      tipId: tipId,
      contentEn: contentEn,
      contentSi: contentSi,
      category: category,
    );
    return true;
  }

  /// Clears all starred tips.
  static Future<void> clearAll() => _box.clear();
}
