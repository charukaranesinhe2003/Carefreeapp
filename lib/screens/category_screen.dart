import 'package:flutter/material.dart';

import '../content/content_repository.dart';
import '../l10n/strings.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/article_row.dart';
import '../widgets/lang_builder.dart';
import 'article_screen.dart';

/// S3 – Category list screen (e.g. "Food & Nutrition", "Our Body").
///
/// Receives a [categoryId] and renders the matching articles with filter chips.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const _repo = BundledRepository();

  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, lang) {
        final category = _repo.categoryById(widget.categoryId);
        if (category == null) {
          return Scaffold(
            appBar: AppTopBar(title: '?'),
            body: const Center(child: Text('Category not found')),
          );
        }

        final articles = _repo.articles(
          categoryId: widget.categoryId,
          filterTag: _activeFilter,
        );

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppTopBar(title: category.title.of(lang)),
          body: Column(
            children: [
              // ─── Filter chips ─────────────────────────────────
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: category.filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final filter = category.filters[i];
                    return Center(
                      child: AppChip(
                        label: filter.label.of(lang),
                        selected: _activeFilter == filter.id,
                        onTap: () =>
                            setState(() => _activeFilter = filter.id),
                      ),
                    );
                  },
                ),
              ),

              // ─── Article list ─────────────────────────────────
              Expanded(
                child: articles.isEmpty
                    ? Center(
                        child: Text(
                          t('search_no_results', lang: lang),
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: articles.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final article = articles[i];
                          return ArticleRow(
                            title: article.title.of(lang),
                            summary: article.summary.of(lang),
                            meta: t('min_read', lang: lang, params: {
                              'n': '${article.readMinutes}',
                            }),
                            icon: _iconForHero(article.hero),
                            onTap: () => _openArticle(article.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openArticle(String articleId) {
    AppRoutes.push(context, ArticleScreen(articleId: articleId));
  }

  static IconData _iconForHero(String hero) {
    return switch (hero) {
      'plate' => Icons.restaurant,
      'water' => Icons.water_drop,
      'cycle' => Icons.autorenew,
      'drop' => Icons.water_drop_outlined,
      'hygiene' => Icons.clean_hands,
      'school' => Icons.school,
      _ => Icons.article,
    };
  }
}
