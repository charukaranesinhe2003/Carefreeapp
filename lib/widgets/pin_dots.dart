import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Four dots that fill as PIN digits are entered. Digits are never displayed.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.total = 4,
    this.error = false,
  });

  final int filled;
  final int total;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fillColor = error ? AppTheme.primaryDark : AppTheme.primaryColor;
    return Semantics(
      label: t('pin_digits_entered', params: {
        'filled': '$filled',
        'total': '$total',
      }),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Container(
                key: ValueKey('pin-dot-$i'),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled ? fillColor : Colors.transparent,
                  border: Border.all(color: fillColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
