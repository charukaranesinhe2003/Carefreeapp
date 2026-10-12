import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.history;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const BackButtonRound(),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Visit history', style: Theme.of(context).textTheme.displayLarge),
                        SizedBox(height: 2),
                        Text(
                          'Every pharmacy you opened',
                          style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: items.isEmpty ? null : app.clearHistory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${items.length} saved visits',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  RiseIn(
                    index: 0,
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              LiveDot(size: 8),
                              SizedBox(width: 8),
                              Text('Live location synced', style: TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app.locationOn
                                ? 'Visits are saved on this device and stay in step with nearby results.'
                                : 'Turn on location to keep distances current with these visits.',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ServiceTag('${app.openVisits} open'),
                              ServiceTag('${app.freeVisits} free'),
                              ServiceTag('${app.closedVisits} closed'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'ALL RECENT PHARMACIES',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text('${items.length} items', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 42, color: Color(0xFFD4C4CC)),
                          SizedBox(height: 8),
                          Text('No history yet', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      RiseIn(
                        index: i + 1,
                        child: _HistoryCard(
                          visit: items[i],
                          onTap: () => openPlace(context, placeForHistory(items[i])),
                          onDelete: () => app.removeHistory(items[i].placeId),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.visit,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryVisit visit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final place = placeForHistory(visit);
    final distance = app.distanceLabel(place);
    return Pressable(
      onTap: onTap,
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlacePhoto(place: place, height: 120),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(visit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Visited ${visit.visitedOn} · $distance away${visit.note.isEmpty ? '' : ' · ${visit.note}'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusPill(label: visit.badge),
                const Spacer(),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Remove', style: TextStyle(color: Color(0xFFDC2626))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in visit.tags) ServiceTag(tag)],
            ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
