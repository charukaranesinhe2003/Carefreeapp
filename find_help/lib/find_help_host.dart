import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/shell_screen.dart';
import 'theme.dart';

/// Runs Find Help on its own navigator, underneath [AppScope].
///
/// Cycle Care pushes this as a route. Screens and dialogs opened from here
/// stay on this navigator, so they can still read notes, reminders, supplies,
/// and saved places.
class FindHelpHost extends StatefulWidget {
  const FindHelpHost({super.key});

  @override
  State<FindHelpHost> createState() => _FindHelpHostState();
}

class _FindHelpHostState extends State<FindHelpHost> {
  final _controller = AppController();
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPop(Object? result) {
    final inner = _navKey.currentState;
    if (inner != null && inner.canPop()) {
      inner.pop(result);
      return;
    }
    final parent = Navigator.of(context);
    if (parent.canPop()) parent.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(),
      child: AppScope(
        controller: _controller,
        child: NavigatorPopHandler<Object?>(
          onPopWithResult: _onPop,
          child: Navigator(
            key: _navKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const ShellScreen(),
              );
            },
          ),
        ),
      ),
    );
  }
}
