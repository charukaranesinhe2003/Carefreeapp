import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Vertical list row used by categories, search results and the library.
class ArticleRow extends StatelessWidget {
  const ArticleRow({
    super.key,
    required this.title,
    required this.summary,
    required this.meta,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String summary;

  /// Small line under the summary, for example "3 min read".
  final String meta;
  final IconData icon;
  final VoidCallback onTap;

  /// Replaces the chevron, for example a "Read Offline" pill.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Icon(
                            Icons.chevron_right,
                            color: AppTheme.textLight,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
