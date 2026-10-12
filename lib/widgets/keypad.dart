import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Fixed-layout PIN pad: 1 to 9, then 0 centred on the bottom row and Delete
/// on the bottom right. Round keys are 72 dp (above the 64 dp minimum).
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  /// False while the PIN is locked out.
  final bool enabled;

  static const double _keySize = 72;
  static const double _gap = 20;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                keys[i],
              ],
            ],
          ),
        );

    Widget digit(String d) => _KeyButton(
          key: ValueKey('keypad-$d'),
          semanticsLabel: d,
          onTap: enabled ? () => onDigit(d) : null,
          child: Text(
            d,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          const SizedBox(width: _keySize, height: _keySize),
          digit('0'),
          _KeyButton(
            key: const ValueKey('keypad-delete'),
            semanticsLabel: t('delete'),
            onTap: enabled ? onDelete : null,
            child: const Icon(
              Icons.backspace_outlined,
              color: AppTheme.textDark,
              size: 26,
            ),
          ),
        ]),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap != null ? 1 : 0.4,
        child: Material(
          color: AppTheme.cardColor,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: Keypad._keySize,
              height: Keypad._keySize,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
