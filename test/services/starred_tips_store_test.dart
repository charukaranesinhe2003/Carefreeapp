import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cycle_care/models/starred_tip.dart';
import 'package:cycle_care/services/starred_tips_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_starred_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(StarredTipAdapter());
    }
    await Hive.openBox<StarredTip>(StarredTipsStore.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await Hive.box<StarredTip>(StarredTipsStore.boxName).clear();
  });

  group('StarredTipsStore', () {
    // ── CREATE ─────────────────────────────────────────────────────

    test('initially empty', () {
      expect(StarredTipsStore.count, 0);
      expect(StarredTipsStore.isStarred('tip-warm-bottle'), isFalse);
      expect(StarredTipsStore.all(), isEmpty);
    });

    test('star() adds a tip to the store', () async {
      await StarredTipsStore.star(
        tipId: 'tip-warm-bottle',
        contentEn: 'Hold a warm water bottle on your lower belly.',
        contentSi: 'වේදනාව සමනය කිරීමට පහළ බඩ මත උණු වතුර බෝතලයක් තබා ගන්න.',
        category: 'daily_tip',
      );

      expect(StarredTipsStore.count, 1);
      expect(StarredTipsStore.isStarred('tip-warm-bottle'), isTrue);
      final items = StarredTipsStore.all();
      expect(items.length, 1);
      expect(items.first.tipId, 'tip-warm-bottle');
      expect(items.first.contentEn, contains('warm water'));
      expect(items.first.category, 'daily_tip');
    });

    test('star() is idempotent – does not duplicate', () async {
      await StarredTipsStore.star(
        tipId: 'tip-drink-water',
        contentEn: 'Drink water.',
        contentSi: 'වතුර බොන්න.',
      );
      await StarredTipsStore.star(
        tipId: 'tip-drink-water',
        contentEn: 'Drink water.',
        contentSi: 'වතුර බොන්න.',
      );
      expect(StarredTipsStore.count, 1);
    });

    // ── READ ──────────────────────────────────────────────────────

    test('all() sorts newest starred first', () async {
      final earlier = DateTime(2026, 9, 10);
      final later = DateTime(2026, 9, 20);

      await StarredTipsStore.star(
        tipId: 'tip-1',
        contentEn: 'First',
        contentSi: 'පළමු',
        at: earlier,
      );
      await StarredTipsStore.star(
        tipId: 'tip-2',
        contentEn: 'Second',
        contentSi: 'දෙවන',
        at: later,
      );

      final all = StarredTipsStore.all();
      expect(all.length, 2);
      expect(all.first.tipId, 'tip-2');
      expect(all.last.tipId, 'tip-1');
    });

    test('byCategory() filters by category', () async {
      await StarredTipsStore.star(
        tipId: 'tip-a',
        contentEn: 'A',
        contentSi: 'ඒ',
        category: 'daily_tip',
      );
      await StarredTipsStore.star(
        tipId: 'tip-b',
        contentEn: 'B',
        contentSi: 'බී',
        category: 'nutrition',
      );
      await StarredTipsStore.star(
        tipId: 'tip-c',
        contentEn: 'C',
        contentSi: 'සී',
        category: 'daily_tip',
      );

      final dailyTips = StarredTipsStore.byCategory('daily_tip');
      expect(dailyTips.length, 2);
      expect(dailyTips.every((t) => t.category == 'daily_tip'), isTrue);

      final nutrition = StarredTipsStore.byCategory('nutrition');
      expect(nutrition.length, 1);
      expect(nutrition.first.tipId, 'tip-b');
    });

    test('get() returns the tip or null', () async {
      await StarredTipsStore.star(
        tipId: 'tip-x',
        contentEn: 'X',
        contentSi: 'එක්ස්',
      );

      expect(StarredTipsStore.get('tip-x'), isNotNull);
      expect(StarredTipsStore.get('tip-x')!.tipId, 'tip-x');
      expect(StarredTipsStore.get('nonexistent'), isNull);
    });

    // ── UPDATE ─────────────────────────────────────────────────────

    test('updateCategory() changes the category', () async {
      await StarredTipsStore.star(
        tipId: 'tip-update',
        contentEn: 'Update me',
        contentSi: 'යාවත්කාලීන කරන්න',
        category: 'daily_tip',
      );

      expect(StarredTipsStore.get('tip-update')!.category, 'daily_tip');

      await StarredTipsStore.updateCategory('tip-update', 'important');

      expect(StarredTipsStore.get('tip-update')!.category, 'important');
      // Count should not change.
      expect(StarredTipsStore.count, 1);
    });

    test('updateCategory() does nothing for unknown id', () async {
      // Should not throw.
      await StarredTipsStore.updateCategory('nonexistent', 'important');
      expect(StarredTipsStore.count, 0);
    });

    // ── DELETE ─────────────────────────────────────────────────────

    test('unstar() removes a tip', () async {
      await StarredTipsStore.star(
        tipId: 'tip-delete',
        contentEn: 'Delete me',
        contentSi: 'මකන්න',
      );
      expect(StarredTipsStore.isStarred('tip-delete'), isTrue);

      await StarredTipsStore.unstar('tip-delete');
      expect(StarredTipsStore.count, 0);
      expect(StarredTipsStore.isStarred('tip-delete'), isFalse);
    });

    test('toggle() stars when not starred, unstars when starred', () async {
      // 1. Toggle when not starred -> stars it.
      final result1 = await StarredTipsStore.toggle(
        tipId: 'tip-toggle',
        contentEn: 'Toggle me',
        contentSi: 'ටොගල් කරන්න',
      );
      expect(result1, isTrue);
      expect(StarredTipsStore.isStarred('tip-toggle'), isTrue);

      // 2. Toggle when starred -> unstars it.
      final result2 = await StarredTipsStore.toggle(
        tipId: 'tip-toggle',
        contentEn: 'Toggle me',
        contentSi: 'ටොගල් කරන්න',
      );
      expect(result2, isFalse);
      expect(StarredTipsStore.isStarred('tip-toggle'), isFalse);
    });

    test('clearAll() removes every starred tip', () async {
      await StarredTipsStore.star(
        tipId: 'tip-1',
        contentEn: 'One',
        contentSi: 'එක',
      );
      await StarredTipsStore.star(
        tipId: 'tip-2',
        contentEn: 'Two',
        contentSi: 'දෙක',
      );
      expect(StarredTipsStore.count, 2);

      await StarredTipsStore.clearAll();
      expect(StarredTipsStore.count, 0);
      expect(StarredTipsStore.all(), isEmpty);
    });
  });
}
