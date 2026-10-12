import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../content/content_repository.dart';
import '../content/content_types.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../models/saved_article.dart';
import '../models/starred_tip.dart';
import '../routes.dart';
import '../services/saved_articles_store.dart';
import '../services/starred_tips_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/article_row.dart';
import '../widgets/lang_builder.dart';
import '../widgets/topic_tile.dart';
import 'article_screen.dart';
import 'category_screen.dart';
import 'myth_buster_screen.dart';
import 'offline_library_screen.dart';
import 'starred_tips_screen.dart';

/// S2 – Education Hub (the **Learn** tab).
///
/// This is NOT the existing [DashboardScreen] (Member 2's cycle dashboard).
/// It is a new screen for the Private Education subsystem.
class EducationHubScreen extends StatefulWidget {
  const EducationHubScreen({super.key});

  @override
  State<EducationHubScreen> createState() => _EducationHubScreenState();
}

class _EducationHubScreenState extends State<EducationHubScreen> {
  static const _repo = BundledRepository();

  final TextEditingController _searchCtrl = TextEditingController();
  List<Article>? _searchResults;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query, Lang lang) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _searchResults = _repo.search(query, lang));
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchResults = null);
  }

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, lang) {
        final tip = _repo.tipForDate(DateTime.now());
        final isSearching = _searchResults != null;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ─── Header ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        // Flower / logo tile.
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_florist,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              t('greeting', lang: lang),
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Search field ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (q) => _onSearch(q, lang),
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: t('search_hint', lang: lang),
                        hintStyle: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textLight,
                        ),
                        suffixIcon: isSearching
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppTheme.textLight),
                                onPressed: _clearSearch,
                                tooltip: t('back', lang: lang),
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Search results OR main content ─────────────
                if (isSearching) ...[
                  _searchResults!.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 48, color: AppTheme.textLight),
                                const SizedBox(height: 12),
                                Text(
                                  t('search_no_results', lang: lang),
                                  style: const TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          sliver: SliverList.separated(
                            itemCount: _searchResults!.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final article = _searchResults![i];
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
                ] else ...[
                  // ─── Daily Health Tip ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _DailyTipCard(
                        tip: tip,
                        lang: lang,
                        onReadMore: tip.articleId != null
                            ? () => _openArticle(tip.articleId!)
                            : null,
                        onStar: () => _toggleStar(tip, lang),
                      ),
                    ),
                  ),

                  // ─── Explore Topics heading ─────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        t('explore_topics', lang: lang),
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  // ─── 2x2 Topic grid ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ValueListenableBuilder<Box<SavedArticle>>(
                        valueListenable: SavedArticlesStore.listenable,
                        builder: (context, box, _) {
                          final savedCount = box.length;
                          return ValueListenableBuilder<Box<StarredTip>>(
                            valueListenable: StarredTipsStore.listenable,
                            builder: (context, starredBox, _) {
                              final starredCount = starredBox.length;
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TopicTile(
                                          title: t('topic_our_body', lang: lang),
                                          subtitle: t('topic_our_body_sub',
                                              lang: lang),
                                          icon: Icons.favorite_outline,
                                          onTap: () => _openCategory('our-body'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TopicTile(
                                          title: t('topic_food', lang: lang),
                                          subtitle:
                                              t('topic_food_sub', lang: lang),
                                          icon: Icons.restaurant,
                                          onTap: () => _openCategory('food-diet'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TopicTile(
                                          title: t('topic_myth', lang: lang),
                                          subtitle:
                                              t('topic_myth_sub', lang: lang),
                                          icon: Icons.psychology,
                                          onTap: () => AppRoutes.push(
                                            context,
                                            const MythBusterScreen(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TopicTile(
                                          title: t('topic_library', lang: lang),
                                          subtitle: t('guides_offline',
                                              lang: lang,
                                              params: {'n': '$savedCount'}),
                                          icon: Icons.bookmark_outline,
                                          onTap: () => AppRoutes.push(
                                            context,
                                            const OfflineLibraryScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TopicTile(
                                          title: t('topic_starred', lang: lang),
                                          subtitle: t('topic_starred_sub',
                                              lang: lang,
                                              params: {'n': '$starredCount'}),
                                          icon: Icons.star_outline,
                                          onTap: () => AppRoutes.push(
                                            context,
                                            const StarredTipsScreen(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom padding.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Navigation helpers ──────────────────────────────────────────

  void _toggleStar(DailyTip tip, Lang lang) async {
    final starred = await StarredTipsStore.toggle(
      tipId: tip.id,
      contentEn: tip.text.en,
      contentSi: tip.text.si,
      category: 'daily_tip',
    );
    if (mounted) {
      AppToast.show(
        context,
        icon: starred ? Icons.star : Icons.star_border,
        message: starred
            ? t('starred_added', lang: lang)
            : t('starred_removed', lang: lang),
      );
    }
  }

  void _openCategory(String categoryId) {
    AppRoutes.push(context, CategoryScreen(categoryId: categoryId));
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

// ── Daily Health Tip card ───────────────────────────────────────────

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({
    required this.tip,
    required this.lang,
    this.onReadMore,
    this.onStar,
  });

  final DailyTip tip;
  final Lang lang;
  final VoidCallback? onReadMore;
  final VoidCallback? onStar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFF493AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                t('daily_tip', lang: lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (onStar != null)
                GestureDetector(
                  onTap: onStar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      StarredTipsStore.isStarred(tip.id)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.text.of(lang),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          if (onReadMore != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onReadMore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t('read_more', lang: lang),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: AppTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
