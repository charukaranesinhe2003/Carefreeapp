import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_care/content/content_repository.dart';
import 'package:cycle_care/content/seed_articles.dart';
import 'package:cycle_care/content/seed_tips_quiz.dart';

void main() {
  const repo = BundledRepository();

  group('Content validation', () {
    test('every article has both EN and SI text', () {
      for (final article in seedArticles) {
        for (final loc in article.allTexts) {
          expect(loc.en, isNotEmpty,
              reason: 'Article "${article.id}" has empty EN text');
          expect(loc.si, isNotEmpty,
              reason: 'Article "${article.id}" has empty SI text');
        }
      }
    });

    test('every article has a valid categoryId', () {
      final validIds = seedCategories.map((c) => c.id).toSet();
      for (final article in seedArticles) {
        expect(validIds, contains(article.categoryId),
            reason:
                'Article "${article.id}" has unknown categoryId "${article.categoryId}"');
      }
    });

    test('article ids are unique', () {
      final ids = seedArticles.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Duplicate article ids found');
    });

    test('every quiz question has both EN and SI text', () {
      for (final q in seedMythQuestions) {
        expect(q.statement.en, isNotEmpty,
            reason: 'Question "${q.id}" has empty EN statement');
        expect(q.statement.si, isNotEmpty,
            reason: 'Question "${q.id}" has empty SI statement');
        expect(q.explanation.en, isNotEmpty,
            reason: 'Question "${q.id}" has empty EN explanation');
        expect(q.explanation.si, isNotEmpty,
            reason: 'Question "${q.id}" has empty SI explanation');
      }
    });

    test('quiz question ids are unique', () {
      final ids = seedMythQuestions.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate quiz question ids found');
    });

    test('every daily tip has both EN and SI text', () {
      for (final tip in seedTips) {
        expect(tip.text.en, isNotEmpty,
            reason: 'Tip "${tip.id}" has empty EN text');
        expect(tip.text.si, isNotEmpty,
            reason: 'Tip "${tip.id}" has empty SI text');
      }
    });

    test('daily tip ids are unique', () {
      final ids = seedTips.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate daily tip ids found');
    });

    test('tip articleId references exist', () {
      final articleIds = seedArticles.map((a) => a.id).toSet();
      for (final tip in seedTips) {
        if (tip.articleId != null) {
          expect(articleIds, contains(tip.articleId),
              reason:
                  'Tip "${tip.id}" references unknown articleId "${tip.articleId}"');
        }
      }
    });

    test('BundledRepository.categories returns all categories', () {
      expect(repo.categories().length, seedCategories.length);
    });

    test('BundledRepository.categoryById works', () {
      for (final cat in seedCategories) {
        expect(repo.categoryById(cat.id), isNotNull);
      }
      expect(repo.categoryById('nonexistent'), isNull);
    });

    test('BundledRepository.articles filters by category', () {
      for (final cat in seedCategories) {
        final articles = repo.articles(categoryId: cat.id);
        for (final a in articles) {
          expect(a.categoryId, cat.id);
        }
      }
    });

    test('BundledRepository.tipForDate is deterministic', () {
      final date = DateTime(2025, 1, 15);
      final tip1 = repo.tipForDate(date);
      final tip2 = repo.tipForDate(date);
      expect(tip1.id, tip2.id);
    });

    test('minimum content counts', () {
      expect(seedArticles.length, greaterThanOrEqualTo(6),
          reason: 'Plan requires at least 6 articles');
      expect(seedTips.length, greaterThanOrEqualTo(5),
          reason: 'Plan requires at least 5 daily tips');
      expect(seedMythQuestions.length, equals(5),
          reason: 'Plan specifies 5 myth questions');
    });

    test('every filter tag on an article matches its category filters', () {
      for (final article in seedArticles) {
        final category = repo.categoryById(article.categoryId);
        expect(category, isNotNull,
            reason: 'Article "${article.id}" has unknown categoryId');
        final validFilterIds =
            category!.filters.map((f) => f.id).toSet()..remove(allFilterId);
        for (final tag in article.filterTags) {
          expect(validFilterIds, contains(tag),
              reason:
                  'Article "${article.id}" has unknown filter tag "$tag" for category "${article.categoryId}"');
        }
      }
    });
  });
}
