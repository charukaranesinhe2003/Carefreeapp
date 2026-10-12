import '../l10n/lang.dart';
import 'content_types.dart';
import 'seed_articles.dart';
import 'seed_tips_quiz.dart';

/// Single access point for education content.
///
/// All content is bundled in the app today ([BundledRepository]). If articles
/// ever move to remote delivery, this is where cache-on-save would be added:
/// fetch and store the article body when the user taps "Save To Offline Library".
abstract class ContentRepository {
  List<ArticleCategory> categories();

  ArticleCategory? categoryById(String id);

  /// Articles in a category. [filterTag] of null or `all` means no filter.
  List<Article> articles({required String categoryId, String? filterTag});

  Article? articleById(String id);

  /// Offline, client-side search in the given language (title, summary, tags).
  List<Article> search(String query, Lang lang);

  /// Deterministic for a given calendar day.
  DailyTip tipForDate(DateTime date);

  /// The questions in their stored order (the quiz shuffles per run).
  List<MythQuestion> mythQuestions();

  /// All bundled daily tips.
  List<DailyTip> get tips;
}

class BundledRepository implements ContentRepository {
  const BundledRepository();

  @override
  List<ArticleCategory> categories() => seedCategories;

  @override
  ArticleCategory? categoryById(String id) {
    for (final category in seedCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  List<Article> articles({required String categoryId, String? filterTag}) {
    final inCategory = seedArticles.where((a) => a.categoryId == categoryId);
    if (filterTag == null || filterTag == allFilterId) {
      return inCategory.toList();
    }
    return inCategory.where((a) => a.filterTags.contains(filterTag)).toList();
  }

  @override
  Article? articleById(String id) {
    for (final article in seedArticles) {
      if (article.id == id) return article;
    }
    return null;
  }

  @override
  List<Article> search(String query, Lang lang) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return seedArticles.where((a) {
      final haystack = [
        a.title.of(lang),
        a.summary.of(lang),
        a.label.of(lang),
        ...a.filterTags,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  DailyTip tipForDate(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final daysSinceEpoch = day.difference(DateTime.utc(1970)).inDays;
    return seedTips[daysSinceEpoch % seedTips.length];
  }

  @override
  List<MythQuestion> mythQuestions() => seedMythQuestions;

  @override
  List<DailyTip> get tips => seedTips;
}
