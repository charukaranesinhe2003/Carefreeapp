import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../content/content_repository.dart';
import '../content/content_types.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../models/saved_article.dart';
import '../routes.dart';
import '../services/metrics_service.dart';
import '../services/saved_articles_store.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/hide_button.dart';
import '../widgets/lang_builder.dart';
import 'main_screen.dart';

/// S4 & S5 – Full Article Reading Screen (REQ-3.2).
///
/// Features:
/// - Pink hero illustration area with top-left circular back button & top-right [HideButton].
/// - Content sheet with rounded top corners overlapping hero:
///   - Category tag chip (e.g. "Nutrition Guide").
///   - Two-toned title (e.g. "Iron-Rich Foods For Stronger Energy" with second line in accent colour).
///   - Body blocks: headings, paragraphs, bullet lists, and "Village Tip" callout card with leaf icon.
/// - Pinned bottom bar:
///   - Unsaved: Wide primary pill "Save To Offline Library" (maroon).
///   - Saved: Green outlined chip "✓ Saved Offline" (reversible toggle).
/// - [HideButton] (REQ-3.1 panic button):
///   - One tap, no confirmation.
///   - Dismisses active toasts.
///   - Locks in-memory session if provider present.
///   - Immediately calls [AppRoutes.resetTo] to [MainScreen], clearing the entire stack so Android Back cannot reopen the article.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({
    super.key,
    required this.articleId,
    this.repository = const BundledRepository(),
  });

  final String articleId;
  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    MetricsService.instance.record('article_open', {'articleId': articleId});
    return PopScope(
      canPop: true,
      child: LangBuilder(
        builder: (context, lang) {
          final article = repository.articleById(articleId);
          if (article == null) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                title: const Text('Article not found'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: const Center(child: Text('Article not found')),
            );
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // ── Layer 0: Pink Hero Header & Illustration ────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 240,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF14E80),
                          Color(0xFFE83A6D),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: _HeroIllustration(hero: article.hero),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Layer 1: Overlapping Scrollable Content Sheet ────
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Spacer to leave hero banner visible
                        const SizedBox(height: 195),

                        // Overlapping white sheet with rounded top corners
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 195,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category tag chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE8EF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  article.label.of(lang),
                                  style: const TextStyle(
                                    color: Color(0xFFB01848),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Two-toned article title
                              _ArticleTitle(title: article.title.of(lang)),
                              const SizedBox(height: 16),

                              // Render body blocks
                              for (final block in article.body)
                                _buildBlock(context, block, lang),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Layer 2: Pinned Top Bar (Back & HIDE) ────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top-left circular back button
                          Semantics(
                            button: true,
                            label: t('back', lang: lang),
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.of(context).maybePop(),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Center(
                                    child: Icon(
                                      Icons.chevron_left,
                                      color: AppTheme.textDark,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Top-right high-contrast HIDE button
                          HideButton(
                            onHide: () => _handleHide(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Layer 3: Pinned Bottom Save Button ──────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                        child: ValueListenableBuilder<Box<SavedArticle>>(
                          valueListenable: SavedArticlesStore.listenable,
                          builder: (context, box, child) {
                            final isSaved =
                                SavedArticlesStore.isSaved(article.id);

                            if (isSaved) {
                              // S5: Green outlined chip "✓ Saved Offline"
                              return Material(
                                color: const Color(0xFFF0FDF4),
                                shape: const StadiumBorder(
                                  side: BorderSide(
                                    color: AppTheme.success,
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _unsaveArticle(
                                    context,
                                    article.id,
                                    lang,
                                  ),
                                  child: SizedBox(
                                    height: 52,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: AppTheme.success,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          t('saved_offline', lang: lang),
                                          style: const TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // S4: Wide primary pill "Save To Offline Library"
                            return Material(
                              color: AppTheme.primaryColor,
                              shape: const StadiumBorder(),
                              elevation: 2,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _saveArticle(
                                  context,
                                  article.id,
                                  lang,
                                ),
                                child: SizedBox(
                                  height: 52,
                                  child: Center(
                                    child: Text(
                                      t('save_offline', lang: lang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Block Builders ───────────────────────────────────────────────

  Widget _buildBlock(BuildContext context, Block block, Lang lang) {
    return switch (block) {
      HeadingBlock(:final text) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            text.of(lang),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ParagraphBlock(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            text.of(lang),
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ListBlock(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7, right: 12),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE83A6D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.of(lang),
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      TipBlock(:final title, :final text) => Container(
          margin: const EdgeInsets.only(top: 8, bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FDF9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDCFCE7),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F9EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${title.of(lang)} :',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text.of(lang),
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    };
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _saveArticle(
    BuildContext context,
    String id,
    Lang lang,
  ) async {
    MetricsService.instance.record('save_offline', {'articleId': id});
    AppToast.show(
      context,
      message: t('toast_saved_title', lang: lang),
      subtitle: t('toast_saved_sub', lang: lang),
      icon: Icons.check_circle,
    );
    await SavedArticlesStore.save(id);
  }

  Future<void> _unsaveArticle(
    BuildContext context,
    String id,
    Lang lang,
  ) async {
    AppToast.show(
      context,
      message: t('toast_removed', lang: lang),
      icon: Icons.bookmark_remove_outlined,
    );
    await SavedArticlesStore.remove(id);
  }

  void _handleHide(BuildContext context) {
    MetricsService.instance.record('hide_tap');

    // 1. Dismiss active toast immediately
    AppToast.dismiss();
    ScaffoldMessenger.of(context).clearSnackBars();

    // 2. Lock the in-memory session if provider is available
    try {
      context.read<SessionState>().lock();
    } catch (_) {}

    // 3. Reset navigator stack to MainScreen instantly with no animation
    AppRoutes.resetTo(context, const MainScreen());

    MetricsService.instance.record('hide_done');
  }
}

// ── Two-toned Title Widget ─────────────────────────────────────────

class _ArticleTitle extends StatelessWidget {
  const _ArticleTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final parts = _splitTitle(title);
    if (parts == null) {
      return Text(
        title,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: parts.$1,
            style: const TextStyle(color: AppTheme.textDark),
          ),
          TextSpan(
            text: parts.$2,
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  static (String, String)? _splitTitle(String text) {
    if (text.contains(' For ')) {
      final idx = text.indexOf(' For ');
      return ('${text.substring(0, idx + 4)}\n', text.substring(idx + 5));
    }
    if (text.contains(' සඳහා ')) {
      final idx = text.indexOf(' සඳහා ');
      return ('${text.substring(0, idx + 5)}\n', text.substring(idx + 6));
    }
    if (text.contains('\n')) {
      final idx = text.indexOf('\n');
      return (text.substring(0, idx + 1), text.substring(idx + 1));
    }
    final words = text.split(' ');
    if (words.length >= 4) {
      final splitIdx = words.length - 2;
      return (
        '${words.sublist(0, splitIdx).join(' ')}\n',
        words.sublist(splitIdx).join(' '),
      );
    }
    return null;
  }
}

// ── Custom Hero Illustration Widget ────────────────────────────────

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.hero});

  final String hero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 90,
      child: CustomPaint(
        painter: _HeroIllustrationPainter(hero: hero),
      ),
    );
  }
}

class _HeroIllustrationPainter extends CustomPainter {
  _HeroIllustrationPainter({required this.hero});

  final String hero;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw sparkle stars around the main illustration
    _drawSparkle(canvas, Offset(cx - 50, cy - 25), 5);
    _drawSparkle(canvas, Offset(cx + 52, cy - 18), 7);
    _drawSparkle(canvas, Offset(cx - 36, cy + 22), 4);
    _drawSparkle(canvas, Offset(cx + 42, cy + 26), 4);

    switch (hero) {
      case 'plate':
        // White ceramic bowl / plate
        final dishPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final dishShadow = Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        // Shadow
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy + 22),
            width: 88,
            height: 22,
          ),
          dishShadow,
        );

        // White bowl
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy + 18),
            width: 84,
            height: 26,
          ),
          dishPaint,
        );

        // Green leafy salad/leaves inside bowl
        final darkGreen = Paint()..color = const Color(0xFF15803D);
        final lightGreen = Paint()..color = const Color(0xFF22C55E);
        final vibrantGreen = Paint()..color = const Color(0xFF4ADE80);

        canvas.drawCircle(Offset(cx - 16, cy + 8), 16, darkGreen);
        canvas.drawCircle(Offset(cx + 14, cy + 7), 17, lightGreen);
        canvas.drawCircle(Offset(cx, cy + 3), 18, vibrantGreen);

        // Red/pink berries / tomatoes
        final redBerry = Paint()..color = const Color(0xFFF43F5E);
        canvas.drawCircle(Offset(cx - 4, cy + 6), 6, redBerry);
        canvas.drawCircle(Offset(cx + 8, cy + 10), 5, redBerry);
        canvas.drawCircle(Offset(cx - 12, cy + 12), 4, redBerry);

      case 'water':
        // Blue glass/bottle with water
        final bottlePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final waterPaint = Paint()..color = const Color(0xFF38BDF8);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 8), width: 44, height: 60),
          const Radius.circular(16),
        );
        canvas.drawRRect(rrect, bottlePaint);

        final waterRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 14), width: 38, height: 44),
          const Radius.circular(12),
        );
        canvas.drawRRect(waterRRect, waterPaint);

        // Droplets
        canvas.drawCircle(Offset(cx + 34, cy), 6, waterPaint);
        canvas.drawCircle(Offset(cx - 30, cy + 12), 4, waterPaint);

      case 'cycle':
        // Cycle arrows with heart
        final ringPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        canvas.drawCircle(Offset(cx, cy + 6), 26, ringPaint);

        final heartPaint = Paint()..color = const Color(0xFFF43F5E);
        canvas.drawCircle(Offset(cx, cy + 6), 12, heartPaint);

      case 'drop':
        // Droplet shape
        final dropPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx, cy + 12), 22, dropPaint);
        final path = Path()
          ..moveTo(cx, cy - 18)
          ..lineTo(cx - 16, cy + 6)
          ..lineTo(cx + 16, cy + 6)
          ..close();
        canvas.drawPath(path, dropPaint);

        final innerHeart = Paint()..color = const Color(0xFFF43F5E);
        canvas.drawCircle(Offset(cx, cy + 10), 10, innerHeart);

      case 'school':
      case 'hygiene':
      default:
        // Clean white card tile with accent circle
        final tilePaint = Paint()..color = Colors.white;
        final tileRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 8), width: 64, height: 50),
          const Radius.circular(16),
        );
        canvas.drawRRect(tileRRect, tilePaint);

        final dotPaint = Paint()..color = const Color(0xFFF43F5E);
        canvas.drawCircle(Offset(cx, cy + 8), 14, dotPaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroIllustrationPainter oldDelegate) =>
      oldDelegate.hero != hero;
}
