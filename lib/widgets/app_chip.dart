import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppChipKind { filter, status }

/// Filter chip (selectable) or green status chip (for example "✓ Saved Offline").
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.kind = AppChipKind.filter,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final AppChipKind kind;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    if (kind == AppChipKind.status) {
      background = AppTheme.success.withValues(alpha: 0.1);
      foreground = AppTheme.success;
      border = AppTheme.success;
    } else if (selected) {
      background = AppTheme.primaryColor;
      foreground = Colors.white;
      border = AppTheme.primaryColor;
    } else {
      background = AppTheme.cardColor;
      foreground = AppTheme.textDark;
      border = AppTheme.primaryColor.withValues(alpha: 0.3);
    }

    // Tappable chips keep a 48 dp tap target.
    final minHeight = onTap != null ? 48.0 : 36.0;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
