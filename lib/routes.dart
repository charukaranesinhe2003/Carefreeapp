import 'package:flutter/material.dart';
import 'screens/stubs/stub_screens.dart';
import 'services/metrics_service.dart';

/// Central place to open screens so navigation stays consistent.
///
/// There is no router package: plain [Navigator] with [MaterialPageRoute].
class AppRoutes {
  AppRoutes._();

  static Future<T?> push<T>(BuildContext context, Widget screen) {
    MetricsService.instance.record('nav', {'screen': screen.runtimeType.toString()});
    return Navigator.of(context)
        .push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  /// Replaces the current route, so the previous screen is not reachable via Back.
  static Future<T?> replace<T, R>(BuildContext context, Widget screen) {
    MetricsService.instance.record('nav', {'screen': screen.runtimeType.toString()});
    return Navigator.of(context)
        .pushReplacement<T, R>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  /// Clears the whole stack and shows [screen] with no transition animation.
  /// Used by HIDE so Back can never return to what was on screen.
  static Future<T?> resetTo<T>(BuildContext context, Widget screen) {
    MetricsService.instance.record('nav_reset', {'screen': screen.runtimeType.toString()});
    return Navigator.of(context).pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  static void openOnboarding(BuildContext context) =>
      push(context, const OnboardingStubScreen());

  static void openPinSetup(BuildContext context) =>
      push(context, const PinSetupStubScreen());

  static void openPharmacy(BuildContext context) =>
      push(context, const PharmacyStubScreen());
}
