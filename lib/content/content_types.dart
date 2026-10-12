import '../l10n/lang.dart';

/// A value that exists in both Sinhala and English.
class Localized<T> {
  const Localized({required this.en, required this.si});

  final T en;
  final T si;

  T of(Lang lang) => lang == Lang.si ? si : en;
}

/// One piece of article body content.
sealed class Block {
  const Block();

  /// Every localized string in this block (used by content validation tests).
  Iterable<Localized<String>> get texts;
}

class HeadingBlock extends Block {
  const HeadingBlock(this.text);
  final Localized<String> text;

  @override
  Iterable<Localized<String>> get texts => [text];
}

class ParagraphBlock extends Block {
  const ParagraphBlock(this.text);
  final Localized<String> text;

  @override
  Iterable<Localized<String>> get texts => [text];
}

class ListBlock extends Block {
  const ListBlock(this.items);
  final List<Localized<String>> items;

  @override
  Iterable<Localized<String>> get texts => items;
}

/// A highlighted callout, for example the "Village Tip".
class TipBlock extends Block {
  const TipBlock({required this.title, required this.text});
  final Localized<String> title;
  final Localized<String> text;

  @override
  Iterable<Localized<String>> get texts => [title, text];
}

class FilterOption {
  const FilterOption({required this.id, required this.label});

  /// `all` is the reserved id meaning "no filter".
  final String id;
  final Localized<String> label;
}

class ArticleCategory {
  const ArticleCategory({
    required this.id,
    required this.title,
    required this.filters,
  });

  /// `our-body` or `food-diet`.
  final String id;
  final Localized<String> title;
  final List<FilterOption> filters;
}

class Article {
  const Article({
    required this.id,
    required this.categoryId,
    required this.filterTags,
    required this.label,
    required this.title,
    required this.summary,
    required this.readMinutes,
    required this.hero,
    required this.body,
  });

  /// Stable id, for example `iron-rich-foods`. Other members may deep-link to it.
  final String id;
  final String categoryId;

  /// `cramp-relief`, `vitamins`, `hormones` or `hygiene`.
  final List<String> filterTags;

  /// Small category tag, for example "Nutrition Guide".
  final Localized<String> label;
  final Localized<String> title;
  final Localized<String> summary;
  final int readMinutes;

  /// Local icon id used to draw the hero illustration (no remote images).
  final String hero;
  final List<Block> body;

  Iterable<Localized<String>> get allTexts sync* {
    yield label;
    yield title;
    yield summary;
    for (final block in body) {
      yield* block.texts;
    }
  }
}

class MythQuestion {
  const MythQuestion({
    required this.id,
    required this.statement,
    required this.isMyth,
    required this.explanation,
  });

  final String id;
  final Localized<String> statement;
  final bool isMyth;
  final Localized<String> explanation;
}

class DailyTip {
  const DailyTip({required this.id, required this.text, this.articleId});

  final String id;
  final Localized<String> text;

  /// Related article opened by "Read More", if one exists.
  final String? articleId;
}
