import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tile for the 2x2 Explore Topics grid. Set [highlighted] for the dark
/// maroon tile (Myth Buster).
class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final background = highlighted ? AppTheme.primaryColor : AppTheme.surface;
    final titleColor = highlighted ? Colors.white : AppTheme.textDark;
    final subtitleColor = highlighted ? Colors.white.withValues(alpha: 0.9) : AppTheme.textLight;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: background,
        elevation: highlighted ? 3 : 1,
        shadowColor: AppTheme.primaryColor.withValues(alpha: highlighted ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppTheme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: highlighted ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
