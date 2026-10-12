import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../models.dart';
import 'feedback_screen.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import 'saved_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.blush,
      body: IndexedStack(
        index: app.tab,
        children: const [
          HomeScreen(),
          ResultsScreen(showBack: false),
          SavedScreen(showBack: false),
          _FeedbackTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: app.tab,
        height: 68,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.blushDeep,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: app.goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me_rounded, color: AppColors.primary),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: AppColors.primary),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.primary),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }
}

class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  Place? _place;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    _place ??= app.history.isEmpty ? places.first : placeForHistory(app.history.first);
    return FeedbackScreen(place: _place!, showBack: false);
  }
}
