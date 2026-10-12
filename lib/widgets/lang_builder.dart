import 'package:flutter/widgets.dart';
import '../l10n/lang.dart';

/// Rebuilds when the language changes. Wrap screens with it so `t()` strings
/// update live.
class LangBuilder extends StatelessWidget {
  const LangBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Lang lang) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(
      valueListenable: LangService.current,
      builder: (context, lang, _) => builder(context, lang),
    );
  }
}
