import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PillButtonStyle { primary, outline, dark }

/// Fully rounded button. At least 52 dp tall (above the 48 dp tap target minimum).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = PillButtonStyle.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonStyle style;

  /// Fill the available width (wide bottom buttons) or wrap the content.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color background;
    final Color foreground;
    final BorderSide side;
    switch (style) {
      case PillButtonStyle.primary:
        background = AppTheme.primaryColor;
        foreground = Colors.white;
        side = BorderSide.none;
      case PillButtonStyle.outline:
        background = Colors.transparent;
        foreground = AppTheme.primaryColor;
        side = const BorderSide(color: AppTheme.primaryColor, width: 1.5);
      case PillButtonStyle.dark:
        background = AppTheme.textDark;
        foreground = Colors.white;
        side = BorderSide.none;
    }

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );

    final button = Material(
      color: background,
      shape: StadiumBorder(side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: expanded
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
