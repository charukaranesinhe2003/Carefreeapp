import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';
import 'history_screen.dart';
import 'filters_screen.dart';
import 'notes_screen.dart';
import 'reminders_screen.dart';
import 'help_screen.dart';
import 'permission_screen.dart';
import 'search_screen.dart';
import 'supplies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _map = false;
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = AppScope.of(context).searchQuery;
    if (!_focus.hasFocus && _search.text != query) {
      _search.text = query;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = app.results;
    final recent = app.history.isEmpty ? null : app.history.first;

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    app.provinceLine,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFF3D6E6)),
                  ),
                  child: Text(app.townLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Find Help\nNearby',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              focusNode: _focus,
              onChanged: app.setSearch,
              onSubmitted: app.rememberSearch,
              decoration: InputDecoration(
                hintText: 'Search Osu Sala, pharmacy, MOH, or a town',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                fillColor: AppColors.card,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          app.setSearch('');
                        },
                        icon: const Icon(Icons.close_rounded, color: AppColors.primary),
                      ),
              ),
            ),
            if (app.searchQuery.trim().length >= 2) ...[
              const SizedBox(height: 10),
              _LiveMatches(places: app.results),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'List view (${results.length} nearby)',
                    selected: !_map,
                    onTap: () => setState(() => _map = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Interactive map',
                    selected: _map,
                    onTap: () => setState(() => _map = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    eyebrow: 'LIVE GPS',
                    title: 'Use My Location',
                    subtitle: app.locating
                        ? 'Finding your location'
                        : app.locationOn
                            ? 'Tracking your location'
                            : app.locationDenied
                                ? 'Search an area yourself'
                                : 'Allow or don\'t allow',
                    detail: app.locationOn
                        ? app.gpsLine
                        : app.locationDenied
                            ? 'Type a town to see places'
                            : 'Kottawa, Sri Lanka',
                    onTap: () => showLocationPrompt(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    eyebrow: 'RECENT VISITS',
                    title: recent?.name ?? 'No visits yet',
                    subtitle: app.history.isEmpty ? 'Open a pharmacy' : '${app.history.length} pharmacies visited',
                    detail: 'Tap to see the full history',
                    photo: recent == null ? null : placeForHistory(recent),
                    onTap: () => openPage(context, const HistoryScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(
                    label: 'Filters',
                    selected: app.filtersNarrowed,
                    onTap: () => openPage(context, const FiltersScreen(), sheet: true),
                  ),
                  const SizedBox(width: 8),
                  for (final chip in const ['Open now', 'Free', 'Pads']) ...[
                    _Chip(
                      label: chip,
                      selected: app.chips.contains(chip),
                      onTap: () => app.toggleChip(chip),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _Chip(
                    label: 'Help',
                    selected: false,
                    onTap: () => openPage(context, const HelpScreen()),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Search area',
                    selected: app.searchQuery.trim().isNotEmpty,
                    onTap: () => openPage(context, const SearchScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Pressable(
              onTap: () => openPage(context, const SuppliesScreen()),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3D6E6)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        value: app.supplyProgress == 0 ? 0.04 : app.supplyProgress,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFF8E4EF),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Visit readiness checklist', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '${app.foundSupplies} of ${app.supplies.length} items ready',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            if (app.dueReminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DueBanner(reminder: app.dueReminders.first),
            ],
            const SizedBox(height: 16),
            Text('Your lists', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ListLink(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved',
                    detail: 'Places you keep',
                    count: '${app.saved.length}',
                    onTap: () => goTab(context, 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ListLink(
                    icon: Icons.inventory_2_rounded,
                    label: 'Supplies',
                    detail: 'Visit checklist',
                    count: '${app.supplies.length}',
                    onTap: () => openPage(context, const SuppliesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ListLink(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notes',
                    detail: 'Write a visit note',
                    count: '${app.notes.length}',
                    onTap: () => openPage(context, const NotesScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ListLink(
                    icon: Icons.alarm_rounded,
                    label: 'Reminders',
                    detail: 'Pick a date and time',
                    count: '${app.reminders.length}',
                    onTap: () => openPage(context, const RemindersScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (app.liveLoading || app.liveMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  app.liveLoading ? 'Finding pharmacies and clinics...' : app.liveMessage,
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.searchQuery.trim().isEmpty ? 'Pharmacies and clinics' : 'Pharmacies and clinics in ${app.searchQuery.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              app.showingClosedInSearch
                  ? 'Nothing open matches. These places are in this area.'
                  : app.locationOn && app.searchQuery.trim().isEmpty
                      ? 'Grouped from your location: under 1 km, 1–2 km, 2–3 km, and 3 km+'
                      : app.searchQuery.trim().isNotEmpty
                          ? 'Grouped from ${app.searchQuery.trim()}: under 1 km, 1–2 km, 2–3 km, and 3 km+'
                          : 'Grouped from Kottawa until you allow location',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (_map)
              SizedBox(
                height: 420,
                child: AnimatedFinderMap(
                  pins: results,
                  onSelect: (place) => openPlace(context, place),
                ),
              )
            else ...[
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No open places match. Turn off Open now or search a town.', textAlign: TextAlign.center),
                )
              else
                for (final band in distanceBands(results, app.originLat, app.originLng).where((band) => band.places.isNotEmpty)) ...[
                  const SizedBox(height: 4),
                  _BandHeader(band: band),
                  const SizedBox(height: 8),
                  for (var i = 0; i < band.places.length; i++) ...[
                    RiseIn(index: i, child: _PharmacyCard(place: band.places[i])),
                    const SizedBox(height: 12),
                  ],
                ],
            ],
            const SizedBox(height: 4),
            Pressable(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: '1990')),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: Color(0xFFE11D48)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Maternity medical emergency', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Call 1990 Suwa Seriya · 24h free ambulance', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Pressable(
      onTap: () => openPlace(context, place),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF3E7EE)),
          boxShadow: const [BoxShadow(color: Color(0x0FE21886), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: PlacePhoto(place: place, height: 120),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(label: place.open ? 'OPEN' : 'CLOSED'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.hoursLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        app.distanceLabel(place),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(place.kindLabel, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(place.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (place.localName != null)
                    Text(place.localName!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(place.address, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  if (place.queue != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Typical queue ${place.queue}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final tag in place.tags.take(4)) ServiceTag(tag)],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Call',
                          filled: false,
                          onTap: () => launchUrl(Uri(scheme: 'tel', path: place.phone.replaceAll(' ', ''))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'View details',
                          filled: true,
                          onTap: () => openPlace(context, place),
                        ),
                      ),
                    ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled ? null : const Color(0xFFFFF4F9),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: const Color(0xFFF6C6E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.primaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LiveMatches extends StatelessWidget {
  const _LiveMatches({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final shown = places.take(6).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3D6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.liveLoading ? 'Updating nearest pharmacies and clinics...' : 'Nearest pharmacies and clinics',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          if (app.liveLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 3, color: AppColors.primary, backgroundColor: Color(0xFFF6C6E0)),
          ],
          const SizedBox(height: 6),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No places match this area yet', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          for (final place in shown)
            Pressable(
              onTap: () => openPlace(context, place),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: PlacePhoto(place: place, height: 52, radius: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '${place.kindLabel} · ${place.area}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(app.distanceLabel(place), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.card : const Color(0xFFF1EEF0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
    this.photo,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;
  final Place? photo;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3D6E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (photo != null) ...[
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: PlacePhoto(place: photo!, height: 42, radius: 10),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const Spacer(),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ListLink extends StatelessWidget {
  const _ListLink({
    required this.icon,
    required this.label,
    required this.detail,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF3D6E6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const Spacer(),
                Text(count, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            const Spacer(),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandHeader extends StatelessWidget {
  const _BandHeader({required this.band});

  final DistanceBand band;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(band.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          '${band.places.length} ${band.places.length == 1 ? 'place' : 'places'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REMINDER DUE', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if (reminder.place.isNotEmpty)
            Text(reminder.place, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Text(reminder.when, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Snooze 10 min',
                  filled: false,
                  onTap: () => app.snoozeReminder(reminder.id),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Done',
                  filled: true,
                  onTap: () => app.completeReminder(reminder.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFF3D6E6)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
