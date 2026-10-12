import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../content/content_repository.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../models/starred_tip.dart';
import '../routes.dart';
import '../services/starred_tips_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/lang_builder.dart';
import 'article_screen.dart';

/// Screen that displays all starred / bookmarked daily health tips.
/// Provides full CRUD: view list, edit category, delete individual tips,
/// and clear all.
class StarredTipsScreen extends StatefulWidget {
  const StarredTipsScreen({super.key});

  @override
  State<StarredTipsScreen> createState() => _StarredTipsScreenState();
}

class _StarredTipsScreenState extends State<StarredTipsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  String _filterCategory = 'all';

  static const _repo = BundledRepository();

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Category helpers ───────────────────────────────────────────────

  Set<String> _categories(List<StarredTip> tips) {
    return {'all', ...tips.map((t) => t.category)};
  }

  List<StarredTip> _filtered(List<StarredTip> tips) {
    if (_filterCategory == 'all') return tips;
    return tips.where((t) => t.category == _filterCategory).toList();
  }

  String _categoryLabel(String cat, Lang lang) {
    return switch (cat) {
      'all' => t('starred_filter_all', lang: lang),
      'daily_tip' => t('starred_cat_daily', lang: lang),
      'myth_fact' => t('starred_cat_myth', lang: lang),
      _ => cat,
    };
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _confirmDelete(StarredTip tip, Lang lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('starred_remove_title', lang: lang)),
        content: Text(
          lang == Lang.si ? tip.contentSi : tip.contentEn,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('back', lang: lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StarredTipsStore.unstar(tip.tipId);
              if (mounted) {
                AppToast.show(
                  context,
                  icon: Icons.star_border,
                  message: t('starred_removed', lang: lang),
                );
              }
            },
            child: Text(
              t('delete', lang: lang),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategory(StarredTip tip, Lang lang) {
    final categories = ['daily_tip', 'myth_fact', 'important', 'nutrition', 'hygiene'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('starred_edit_category', lang: lang),
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map((cat) {
                final isSelected = tip.category == cat;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _categoryIcon(cat),
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                  ),
                  title: Text(
                    _categoryLabel(cat, lang),
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await StarredTipsStore.updateCategory(tip.tipId, cat);
                    if (mounted) {
                      AppToast.show(
                        context,
                        icon: Icons.edit,
                        message: t('starred_category_updated', lang: lang),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(Lang lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('starred_clear_title', lang: lang)),
        content: Text(t('starred_clear_confirm', lang: lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('back', lang: lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StarredTipsStore.clearAll();
              if (mounted) {
                AppToast.show(
                  context,
                  icon: Icons.delete_sweep,
                  message: t('starred_all_cleared', lang: lang),
                );
              }
            },
            child: Text(
              t('delete', lang: lang),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'daily_tip' => Icons.lightbulb_outline,
    'myth_fact' => Icons.psychology,
    'important' => Icons.priority_high,
    'nutrition' => Icons.restaurant,
    'hygiene' => Icons.clean_hands,
    _ => Icons.star,
  };

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LangBuilder(
      builder: (context, lang) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: ValueListenableBuilder<Box<StarredTip>>(
              valueListenable: StarredTipsStore.listenable,
              builder: (context, box, _) {
                final allTips = StarredTipsStore.all();
                final categories = _categories(allTips);
                final filtered = _filtered(allTips);

                return CustomScrollView(
                  slivers: [
                    // ─── Header ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppTheme.textDark,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  t('starred_title', lang: lang),
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (allTips.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined),
                                color: AppTheme.textLight,
                                tooltip: t('starred_clear_title', lang: lang),
                                onPressed: () => _confirmClearAll(lang),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Stats banner ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _StatsBanner(count: allTips.length, lang: lang),
                      ),
                    ),

                    // ─── Category filter chips ────────────────────
                    if (categories.length > 2)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: categories.map((cat) {
                                final selected = _filterCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(_categoryLabel(cat, lang)),
                                    selected: selected,
                                    selectedColor: AppTheme.primaryColor,
                                    backgroundColor: AppTheme.surface,
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: selected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textLight
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _filterCategory = cat),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                    // ─── Tip list or empty state ──────────────────
                    if (allTips.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(lang: lang),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list_off,
                                  size: 48, color: AppTheme.textLight),
                              const SizedBox(height: 12),
                              Text(
                                t('starred_filter_empty', lang: lang),
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final tip = filtered[i];
                            return _StarredTipCard(
                              tip: tip,
                              lang: lang,
                              index: i,
                              onDelete: () => _confirmDelete(tip, lang),
                              onEditCategory: () =>
                                  _showEditCategory(tip, lang),
                              onReadMore: _findArticleId(tip.tipId) != null
                                  ? () => AppRoutes.push(
                                        context,
                                        ArticleScreen(
                                          articleId:
                                              _findArticleId(tip.tipId)!,
                                        ),
                                      )
                                  : null,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Looks up the linked article id from the original tip seed data.
  String? _findArticleId(String tipId) {
    try {
      final tip = _repo.tips.firstWhere((t) => t.id == tipId);
      return tip.articleId;
    } catch (_) {
      return null;
    }
  }
}

// ── Stats Banner ─────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.count, required this.lang});

  final int count;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBB6CE), Color(0xFFF9A8D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('starred_banner_title', lang: lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t('starred_banner_sub', lang: lang, params: {'n': '$count'}),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Starred Tip Card ─────────────────────────────────────────────────

class _StarredTipCard extends StatelessWidget {
  const _StarredTipCard({
    required this.tip,
    required this.lang,
    required this.index,
    required this.onDelete,
    required this.onEditCategory,
    this.onReadMore,
  });

  final StarredTip tip;
  final Lang lang;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEditCategory;
  final VoidCallback? onReadMore;

  String get _displayText => lang == Lang.si ? tip.contentSi : tip.contentEn;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category pill + actions row.
            Row(
              children: [
                GestureDetector(
                  onTap: onEditCategory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIconFor(tip.category),
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _categoryLabelFor(tip.category, lang),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.edit, size: 11, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Starred timestamp.
                Text(
                  _formatDate(tip.starredAt),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tip text.
            Text(
              _displayText,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),

            // Read-more link.
            if (onReadMore != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onReadMore,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('read_more', lang: lang),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppTheme.primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  IconData _categoryIconFor(String cat) => switch (cat) {
    'daily_tip' => Icons.lightbulb_outline,
    'myth_fact' => Icons.psychology,
    'important' => Icons.priority_high,
    'nutrition' => Icons.restaurant,
    'hygiene' => Icons.clean_hands,
    _ => Icons.star,
  };

  String _categoryLabelFor(String cat, Lang lang) => switch (cat) {
    'daily_tip' => t('starred_cat_daily', lang: lang),
    'myth_fact' => t('starred_cat_myth', lang: lang),
    'important' => t('starred_cat_important', lang: lang),
    'nutrition' => t('starred_cat_nutrition', lang: lang),
    'hygiene' => t('starred_cat_hygiene', lang: lang),
    _ => cat,
  };
}

// ── Empty State ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_border,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t('starred_empty_title', lang: lang),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              t('starred_empty_sub', lang: lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
