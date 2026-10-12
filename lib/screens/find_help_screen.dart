import 'package:find_help/app_state.dart';
import 'package:find_help/screens/shell_screen.dart';
import 'package:find_help/theme.dart';
import 'package:flutter/material.dart';

/// Opens the Find Help app that lives in the find_help folder.
class FindHelpScreen extends StatefulWidget {
  const FindHelpScreen({super.key});

  @override
  State<FindHelpScreen> createState() => _FindHelpScreenState();
}

class _FindHelpScreenState extends State<FindHelpScreen> {
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
    return Theme(
      data: buildTheme(),
      child: AppScope(
        controller: _controller,
        child: const ShellScreen(),
      ),
    );
  }
}
