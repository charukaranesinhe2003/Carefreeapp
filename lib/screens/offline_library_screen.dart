import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../content/content_repository.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../models/saved_article.dart';
import '../routes.dart';
import '../services/saved_articles_store.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/hide_button.dart';
import '../widgets/lang_builder.dart';
import '../widgets/pill_button.dart';
import 'article_screen.dart';
import 'category_screen.dart';
import 'main_screen.dart';

/// S6 – Offline Library screen (REQ-3.1, REQ-3.2).
///
/// Displays articles saved to offline storage (Hive `saved_articles` box)
/// sorted newest first. Features:
/// 1. Top bar with back chevron, title, and panic HIDE button.
/// 2. Green-tinted "Zero Internet Required" banner.
/// 3. Reactive saved articles list via [SavedArticlesStore.listenable].
/// 4. "Read Offline" pill and card tapping to open [ArticleScreen].
/// 5. In-library unsave with reversible feedback.
/// 6. Friendly empty state with "Browse topics" action.
class OfflineLibraryScreen extends StatelessWidget {
  const OfflineLibraryScreen({
    super.key,
    this.repository = const BundledRepository(),
  });

  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, lang) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppTopBar(
          title: t('library_title', lang: lang),
          trailing: HideButton(
            onHide: () => _handleHide(context),
          ),
        ),
        body: Column(
          children: [
            // ── 1. Green-tinted Banner ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_done_outlined,
                          color: Color(0xFF16A34A),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('library_banner_title', lang: lang),
                            style: const TextStyle(
                              color: Color(0xFF14532D),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('library_banner_sub', lang: lang),
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Saved Articles List or Empty State ────────────────
            Expanded(
              child: ValueListenableBuilder<Box<SavedArticle>>(
                valueListenable: SavedArticlesStore.listenable,
                builder: (context, box, child) {
                  final savedList = SavedArticlesStore.all();
                  if (savedList.isEmpty) {
                    return _buildEmptyState(context, lang);
                  }
                  return _buildSavedList(context, savedList, lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Saved List ─────────────────────────────────────────────────────

  Widget _buildSavedList(
    BuildContext context,
    List<SavedArticle> savedList,
    Lang lang,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: savedList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final savedEntry = savedList[index];
        final article = repository.articleById(savedEntry.articleId);
        if (article == null) return const SizedBox.shrink();

        final dateFormatted = DateFormat('d MMM').format(savedEntry.savedAt);
        final dateText = t('saved_on', lang: lang, params: {'date': dateFormatted});
        final minReadText = t('min_read', lang: lang, params: {'n': '${article.readMinutes}'});
        final metaText = '$dateText · $minReadText';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openArticle(context, article.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left hero icon tile
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8EF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              _iconForHero(article.hero),
                              color: const Color(0xFFB01848),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title and meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title.of(lang),
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                metaText,
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Unsave / remove button
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_remove_outlined,
                            color: AppTheme.textLight,
                            size: 22,
                          ),
                          tooltip: t('toast_removed', lang: lang),
                          onPressed: () => _unsave(context, article.id, lang),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // "Read Offline" pill action
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: AppTheme.primaryColor,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openArticle(context, article.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t('read_offline', lang: lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, Lang lang) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8EF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bookmark_border_rounded,
                  color: Color(0xFFB01848),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('library_empty_title', lang: lang),
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lang == Lang.si
                  ? 'ඔබ නොබැඳිව කියවීමට සුරකින මාර්ගෝපදේශ මෙහි දිස්වනු ඇත.'
                  : 'Articles you save for offline reading will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: t('browse_topics', lang: lang),
              icon: Icons.explore_outlined,
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  AppRoutes.push(
                    context,
                    const CategoryScreen(categoryId: 'food-diet'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _openArticle(BuildContext context, String articleId) {
    AppRoutes.push(context, ArticleScreen(articleId: articleId));
  }

  Future<void> _unsave(
    BuildContext context,
    String articleId,
    Lang lang,
  ) async {
    AppToast.show(
      context,
      message: t('toast_removed', lang: lang),
      icon: Icons.bookmark_remove_outlined,
    );
    await SavedArticlesStore.remove(articleId);
  }

  void _handleHide(BuildContext context) {
    AppToast.dismiss();
    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      context.read<SessionState>().lock();
    } catch (_) {}
    AppRoutes.resetTo(context, const MainScreen());
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
