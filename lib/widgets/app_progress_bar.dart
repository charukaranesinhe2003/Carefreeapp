import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rounded progress bar, for example the quiz "QUESTION 1 OF 5" bar.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = AppTheme.primaryColor,
    this.trackColor,
  });

  /// 0.0 to 1.0.
  final double value;
  final double height;
  final Color color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          backgroundColor: trackColor ?? color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
