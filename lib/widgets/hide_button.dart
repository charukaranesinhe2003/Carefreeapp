import 'package:flutter/material.dart';
import '../l10n/strings.dart';

/// The panic button (REQ-3.1). Solid, high-contrast and visually heavy: user
/// testing showed people hesitated when it blended into the header, so it must
/// never share the header's colour.
///
/// Kept as its own widget so it can be moved or turned into a FAB later.
class HideButton extends StatelessWidget {
  const HideButton({
    super.key,
    required this.onHide,
    this.label,
    this.backgroundColor = Colors.white,
    this.foregroundColor = const Color(0xFFB01848),
  });

  final VoidCallback onHide;
  final String? label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final text = label ?? t('hide');
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: backgroundColor,
        elevation: 3,
        shape: StadiumBorder(
          side: BorderSide(
            color: foregroundColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onHide,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: foregroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close, color: foregroundColor, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
