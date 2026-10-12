import 'package:flutter/material.dart';

import 'app_state.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page, bool sheet = false})
      : super(
          transitionDuration: const Duration(milliseconds: 460),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: sheet ? const Offset(0, 0.08) : const Offset(0.06, 0.015),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Future<T?> openPage<T>(BuildContext context, Widget page, {bool sheet = false}) {
  return Navigator.of(context).push<T>(AppPageRoute<T>(page: page, sheet: sheet));
}

void goTab(BuildContext context, int index) {
  AppScope.of(context).goToTab(index);
  Navigator.of(context).popUntil((route) => route.isFirst);
}
