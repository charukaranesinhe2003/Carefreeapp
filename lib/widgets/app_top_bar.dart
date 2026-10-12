import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Top bar with a back chevron, a title and an optional right-hand widget.
/// Use as `Scaffold.appBar`. Set [dark] for dark (maroon) screens.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.dark = false,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final bool dark;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppTheme.textDark;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: t('back'),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(Icons.chevron_left, size: 32, color: foreground),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              trailing ?? const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
