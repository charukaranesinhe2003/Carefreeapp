import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'feedback_screen.dart';

void openPlace(BuildContext context, Place place) {
  AppScope.of(context).recordVisit(place);
  openPage(context, DetailsScreen(place: place));
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.place});

  final Place place;

  Future<void> _open(BuildContext context, Uri uri, String fallback) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) showAppSnack(context, fallback);
    } catch (_) {
      if (context.mounted) showAppSnack(context, fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final saved = app.isSaved(place.name);
    final note = app.feedbackFor(place.id);
    final today = DateTime.now().weekday;
    final weekdayHours = place.note == 'Until 4:00 PM' ? '8:00 AM – 4:00 PM' : '8:00 AM – 6:00 PM';
    final hours = [
      for (var day = 1; day <= 5; day++) _DayHours(day, weekdayHours),
      const _DayHours(6, '9:00 AM – 1:00 PM'),
      const _DayHours(7, 'Closed', closed: true),
    ];

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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FACILITY PROFILE',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => openPage(context, FeedbackScreen(place: place)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F7),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFF6C6E0)),
                      ),
                      child: const Text(
                        'Rate',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  RiseIn(
                    index: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        color: AppColors.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 6, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                            PlacePhoto(place: place, height: 180, hero: true),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Hero(
                                          tag: 'place-${place.id}',
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: Text(
                                              place.name,
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusPill(label: place.open ? 'OPEN' : 'CLOSED'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${place.address} · ${AppScope.of(context).distanceLabel(place)} away',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ServiceTag(place.kindLabel),
                                      if (place.free) const ServiceTag('Free supplies'),
                                      if (place.paid) const ServiceTag('Paid'),
                                      if (place.tags.contains('Testing')) const ServiceTag('Testing'),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoRow(icon: Icons.place_rounded, text: place.address),
                                  const SizedBox(height: 8),
                                  _InfoRow(icon: Icons.schedule_rounded, text: place.hoursLine),
                                  const SizedBox(height: 8),
                                  _InfoRow(icon: Icons.call_rounded, text: place.phone),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.blushDeep,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const LiveDot(size: 8, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live location synced · ${AppScope.of(context).distanceLabel(place)} from you now',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Your feedback'),
                          const SizedBox(height: 8),
                          Text(
                            note.experience == 'helped' ? 'This place helped' : 'This place was not quite right',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (note.note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(note.note, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 2,
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Essential stock'),
                          const SizedBox(height: 4),
                          const Text(
                            'Directory listing for this pharmacy, updated in the app.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          for (final line in place.listedStock)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Text(
                                    line.status,
                                    style: TextStyle(
                                      color: line.cold ? const Color(0xFF2563EB) : const Color(0xFF059669),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (place.services.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const SectionLabel('Services'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [for (final service in place.services) ServiceTag(service)],
                            ),
                          ],
                          const SizedBox(height: 12),
                          const SectionLabel('Available services'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [for (final tag in place.tags) ServiceTag(tag)],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 3,
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Opening hours'),
                          const SizedBox(height: 6),
                          for (final row in hours)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          weekdayName(row.day),
                                          style: TextStyle(
                                            color: row.closed
                                                ? const Color(0xFFF87171)
                                                : row.day == today
                                                    ? AppColors.primary
                                                    : const Color(0xFF5C4A55),
                                            fontWeight: row.day == today ? FontWeight.w800 : FontWeight.w500,
                                          ),
                                        ),
                                        if (row.day == today) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.blushDeep,
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                            child: const Text(
                                              'TODAY',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    row.hours,
                                    style: TextStyle(
                                      color: row.closed ? const Color(0xFFF87171) : AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 4,
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Quick actions'),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Call',
                            icon: Icons.call_rounded,
                            onPressed: () => _open(
                              context,
                              Uri(scheme: 'tel', path: place.phone.replaceAll(' ', '')),
                              place.phone,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Pressable(
                            haptic: true,
                            onTap: () => _open(
                              context,
                              Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${place.name} ${place.address}')}',
                              ),
                              place.address,
                            ),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Get directions',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlineButton(
                            label: saved ? 'Saved · manage places' : 'Save this place',
                            onPressed: () {
                              if (!saved) {
                                app.addSaved(
                                  SavedPlace(
                                    id: DateTime.now().millisecondsSinceEpoch,
                                    name: place.name,
                                    area: place.address,
                                    kind: place.kindLabel,
                                    note: place.free ? 'Free supplies available' : (place.note ?? ''),
                                  ),
                                );
                                showAppSnack(context, 'Saved ${place.name}');
                              }
                              goTab(context, 2);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHours {
  const _DayHours(this.day, this.hours, {this.closed = false});

  final int day;
  final String hours;
  final bool closed;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35))),
      ],
    );
  }
}
