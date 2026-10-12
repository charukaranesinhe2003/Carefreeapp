import 'dart:async';
import 'package:flutter/material.dart';
import '../services/metrics_service.dart';
import '../theme/app_theme.dart';

/// Dark bottom pill toast with a green check. Only one toast is shown at a
/// time. Announced politely to screen readers (live region), dismissible by
/// tap, and auto-dismissed after about 4 seconds.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 4),
    double bottomOffset = 24,
  }) {
    MetricsService.instance.record('toast_shown', {'message': message});
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        subtitle: subtitle,
        icon: icon,
        bottomOffset: bottomOffset,
        onTap: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }

  /// Removes the active toast, if any. Called by HIDE.
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null) {
      try {
        if (entry.mounted) entry.remove();
      } catch (_) {}
    }
  }

  /// For test isolation: resets active entry and timer without touching overlays.
  @visibleForTesting
  static void reset() {
    _timer?.cancel();
    _timer = null;
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({
    required this.message,
    required this.subtitle,
    required this.icon,
    required this.bottomOffset,
    required this.onTap,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final double bottomOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset + MediaQuery.viewPaddingOf(context).bottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Material(
                  color: AppTheme.maroon,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: AppTheme.success, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
