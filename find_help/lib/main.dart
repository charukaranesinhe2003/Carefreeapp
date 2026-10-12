import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/shell_screen.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FindHelpApp());
}

class FindHelpApp extends StatefulWidget {
  const FindHelpApp({super.key});

  @override
  State<FindHelpApp> createState() => _FindHelpAppState();
}

class _FindHelpAppState extends State<FindHelpApp> {
  final _controller = AppController();

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

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Find Help Nearby',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) {
          return AuroraBackdrop(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final page = child ?? const SizedBox.shrink();
                final wide = constraints.maxWidth >= 760;
                if (!wide) return page;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 48,
                            offset: Offset(0, 22),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: SizedBox(
                          width: 420,
                          height: math.min(880, constraints.maxHeight - 56),
                          child: page,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        home: const ShellScreen(),
      ),
    );
  }
}
