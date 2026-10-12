import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/metrics_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/keypad.dart';
import '../widgets/lang_builder.dart';
import '../widgets/pin_dots.dart';
import 'main_screen.dart';

/// S1 – Privacy Lock screen (REQ-3.1).
///
/// App entry point. Every cold start shows this screen. The Android Back
/// button is blocked ([PopScope] with `canPop: false`).
class PrivacyLockScreen extends StatefulWidget {
  const PrivacyLockScreen({super.key});

  @override
  State<PrivacyLockScreen> createState() => _PrivacyLockScreenState();
}

class _PrivacyLockScreenState extends State<PrivacyLockScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  String? _error;
  bool _shaking = false;
  Timer? _lockoutTimer;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _shaking = false);
      }
    });

    // Check if there's an active lockout; if so start the countdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MetricsService.instance.record('lock_shown');
      _checkPinSetAndLockout();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPinSetAndLockout() async {
    final session = context.read<SessionState>();
    // If no PIN is set, directly route to MainScreen.
    if (!(await session.isPinSet)) {
      session.unlockForTesting();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
      return;
    }
    // If already locked out from a previous session, start countdown.
    if (session.isLockedOut) {
      _startLockoutTimer();
    }
  }

  void _onDigit(String digit) {
    final session = context.read<SessionState>();
    if (session.isLockedOut || _shaking) return;
    if (_entered.length >= 4) return;

    MetricsService.instance.record('pin_key', {'key': digit});

    setState(() {
      _entered += digit;
      _error = null;
    });

    // Auto-verify on the 4th digit.
    if (_entered.length == 4) {
      _verify();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty || _shaking) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    final session = context.read<SessionState>();
    final ok = await session.tryUnlock(_entered);

    if (!mounted) return;

    if (ok) {
      MetricsService.instance.record('unlocked');
      // Correct: replace with MainScreen (no back to lock).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      MetricsService.instance.record('pin_error');
      // Wrong: shake, clear, show error.
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (!reduceMotion) {
        setState(() => _shaking = true);
        _shakeCtrl.forward(from: 0);
        HapticFeedback.vibrate();
      }

      setState(() {
        _entered = '';
        if (session.isLockedOut) {
          _error = null; // lockout message is shown separately
          _startLockoutTimer();
        } else {
          _error = t('pin_incorrect');
        }
      });
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = context.read<SessionState>();
      if (!session.isLockedOut) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: LangBuilder(
        builder: (context, lang) {
          final session = context.watch<SessionState>();
          final lockedOut = session.isLockedOut;
          final remaining = session.lockoutRemaining;

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Padlock icon in a pink tile.
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Heading.
                      Semantics(
                        header: true,
                        child: Text(
                          t('lock_title', lang: lang),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sub-text.
                      Text(
                        t('lock_subtitle', lang: lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // PIN dots (with shake animation).
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        ),
                        child: PinDots(
                          filled: _entered.length,
                          error: _error != null || lockedOut,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error / lockout message.
                      SizedBox(
                        height: 40,
                        child: Center(
                          child: lockedOut
                              ? Text(
                                  t('pin_locked', lang: lang, params: {
                                    'seconds': '$remaining',
                                  }),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.primaryDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                )
                              : _error != null
                                  ? Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppTheme.primaryDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Keypad.
                      Keypad(
                        onDigit: _onDigit,
                        onDelete: _onDelete,
                        enabled: !lockedOut && !_shaking,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
