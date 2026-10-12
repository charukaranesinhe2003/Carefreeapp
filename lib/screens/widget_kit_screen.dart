import 'package:flutter/material.dart';
import '../content/content_repository.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/article_row.dart';
import '../widgets/hide_button.dart';
import '../widgets/keypad.dart';
import '../widgets/lang_builder.dart';
import '../widgets/pill_button.dart';
import '../widgets/pin_dots.dart';
import '../widgets/topic_tile.dart';

/// Dev-only widget kit screen. Shows every shared widget in both English and
/// Sinhala so they can be visually checked. Available only in debug builds.
///
/// Phase 1 accept criteria: "a dev-only 'kit' screen (debug builds only) shows
/// every shared widget in EN and SI."
class WidgetKitScreen extends StatefulWidget {
  const WidgetKitScreen({super.key});

  @override
  State<WidgetKitScreen> createState() => _WidgetKitScreenState();
}

class _WidgetKitScreenState extends State<WidgetKitScreen> {
  Lang _lang = Lang.en;
  int _pinFilled = 2;
  String _selectedFilter = 'all';
  double _progress = 0.4;

  void _toggleLang() {
    final next = _lang == Lang.en ? Lang.si : Lang.en;
    setState(() => _lang = next);
    LangService.setPreview(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      // This screen should never be used in release builds.
      return true;
    }());

    return LangBuilder(
      builder: (context, lang) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppTopBar(
          title: 'Widget Kit (${lang.name.toUpperCase()})',
          showBack: true,
          trailing: IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Toggle EN/SI',
            onPressed: _toggleLang,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _section('PillButton'),
            PillButton(
              label: t('save_offline', lang: lang),
              onPressed: () {},
              icon: Icons.bookmark_outline,
            ),
            const SizedBox(height: 8),
            PillButton(
              label: t('saved_offline', lang: lang),
              onPressed: () {},
              style: PillButtonStyle.outline,
            ),
            const SizedBox(height: 8),
            PillButton(
              label: t('hide', lang: lang),
              onPressed: () {},
              style: PillButtonStyle.dark,
              icon: Icons.close,
            ),
            const SizedBox(height: 8),
            PillButton(
              label: t('read_more', lang: lang),
              onPressed: () {},
              expanded: false,
            ),

            _section('HideButton (Panic Button)'),
            Row(
              children: [
                HideButton(onHide: () {}),
                const SizedBox(width: 12),
                HideButton(
                  onHide: () {},
                  backgroundColor: AppTheme.maroon,
                  foregroundColor: Colors.white,
                ),
              ],
            ),

            _section('AppChip'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                  label: t('topic_food', lang: lang),
                  selected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                AppChip(
                  label: t('topic_our_body', lang: lang),
                  selected: _selectedFilter == 'body',
                  onTap: () => setState(() => _selectedFilter = 'body'),
                ),
                AppChip(
                  label: t('saved_offline', lang: lang),
                  kind: AppChipKind.status,
                  icon: Icons.check,
                ),
              ],
            ),

            _section('AppTopBar (dark)'),
            Container(
              color: AppTheme.maroon,
              child: AppTopBar(
                title: t('quiz_title', lang: lang),
                dark: true,
                showBack: true,
                onBack: () {},
                trailing: HideButton(onHide: () {}),
              ),
            ),

            _section('HideButton'),
            Row(
              children: [
                HideButton(onHide: () {}, label: t('hide', lang: lang)),
              ],
            ),

            _section('TopicTile'),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: TopicTile(
                      title: t('topic_food', lang: lang),
                      subtitle: t('topic_food_sub', lang: lang),
                      icon: Icons.restaurant,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TopicTile(
                      title: t('topic_myth', lang: lang),
                      subtitle: t('topic_myth_sub', lang: lang),
                      icon: Icons.psychology,
                      highlighted: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            _section('ArticleRow'),
            ArticleRow(
              title: const BundledRepository()
                  .articleById('iron-rich-foods')!
                  .title
                  .of(lang),
              summary: const BundledRepository()
                  .articleById('iron-rich-foods')!
                  .summary
                  .of(lang),
              meta: t('min_read', lang: lang, params: {'n': '3'}),
              icon: Icons.restaurant,
              onTap: () {},
            ),

            _section('AppToast (tap to show)'),
            PillButton(
              label: 'Show Toast',
              onPressed: () {
                AppToast.show(
                  context,
                  message: t('toast_saved_title', lang: lang),
                  subtitle: t('toast_saved_sub', lang: lang),
                );
              },
              expanded: false,
            ),

            _section('AppProgressBar'),
            AppProgressBar(value: _progress),
            const SizedBox(height: 8),
            Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
            ),
            Text(
              t('quiz_progress', lang: lang,
                  params: {'n': '2', 'total': '5'}),
              textAlign: TextAlign.center,
            ),

            _section('PinDots'),
            Center(
              child: PinDots(filled: _pinFilled),
            ),
            const SizedBox(height: 8),
            Center(
              child: PinDots(filled: _pinFilled, error: true),
            ),
            Slider(
              value: _pinFilled.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: '$_pinFilled',
              onChanged: (v) => setState(() => _pinFilled = v.round()),
            ),

            _section('Keypad'),
            Center(
              child: Keypad(
                onDigit: (d) {
                  if (_pinFilled < 4) {
                    setState(() => _pinFilled = _pinFilled + 1);
                  }
                },
                onDelete: () {
                  if (_pinFilled > 0) {
                    setState(() => _pinFilled = _pinFilled - 1);
                  }
                },
              ),
            ),

            _section('LangBuilder (auto-updates above)'),
            Text(
              'Current: ${lang.name.toUpperCase()} — toggle with the 🌐 button',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textLight),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
