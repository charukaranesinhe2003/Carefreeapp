import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'search_screen.dart';

Future<void> showLocationPrompt(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Location access',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => const _LocationDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _LocationDialog extends StatelessWidget {
  const _LocationDialog();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const ColoredBox(color: Color(0x661C1220)),
              ),
            ),
          ),
          Center(
            child: _LocationCard(app: app),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Allow Find Help to use your location?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap Allow, then accept the message from your phone. Pharmacies and clinics near you stay updated as you move.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: app.locating ? 'Waiting for phone permission...' : 'Allow location access',
              height: 48,
              onPressed: app.locating
                  ? null
                  : () async {
                      final current = AppScope.of(context);
                      final ok = await current.enableLocation();
                      if (!context.mounted) return;
                      if (!ok) {
                        showAppSnack(
                          context,
                          current.liveMessage.isEmpty
                              ? 'Location was not allowed. Search a town instead.'
                              : current.liveMessage,
                        );
                        return;
                      }
                      current.setSearch('');
                      await current.loadLivePharmacies();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 8),
            const Text(
              'Or type a town in Sri Lanka and we will list places there.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            OutlineButton(
              label: "Don't allow",
              fill: const Color(0xFFFFF4F9),
              onPressed: () {
                final navigator = Navigator.of(context, rootNavigator: true);
                AppScope.of(context).denyLocation();
                navigator.pop();
                navigator.push(AppPageRoute(page: const SearchScreen()));
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
