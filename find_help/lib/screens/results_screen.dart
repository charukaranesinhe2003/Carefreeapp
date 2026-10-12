import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';
import 'filters_screen.dart';
import 'help_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  var _view = 0;
  int? _selectedId;

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

  Place? _selected(List<Place> results) {
    if (results.isEmpty) return null;
    for (final place in results) {
      if (place.id == _selectedId) return place;
    }
    return results.first;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = app.results;
    final closed = results.isEmpty ? app.closedNearby : const <Place>[];
    final selected = _selected(results);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (widget.showBack) ...[
                    const BackButtonRound(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find help nearby',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            children: [
                              TextSpan(text: app.searchQuery.trim().isEmpty ? 'Showing results near ' : 'Searching '),
                              TextSpan(
                                text: app.searchQuery.trim().isEmpty ? app.areaLabel : app.searchQuery.trim(),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                onChanged: app.setSearch,
                onSubmitted: app.rememberSearch,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search area...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            app.setSearch('');
                          },
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFE7B3CC), size: 18),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedControl(
                index: _view,
                labels: const ['List view', 'Map view'],
                onChanged: (value) => setState(() => _view = value),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChipButton(
                    label: 'Filters',
                    filled: true,
                    icon: Icons.tune_rounded,
                    onTap: () => openPage(context, const FiltersScreen(), sheet: true),
                  ),
                  const SizedBox(width: 8),
                  for (final chip in const ['Open now', 'Free', 'Pads']) ...[
                    _FilterChipButton(
                      label: chip,
                      filled: app.chips.contains(chip),
                      onTap: () => app.toggleChip(chip),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _FilterChipButton(
                    label: 'Help',
                    filled: false,
                    onTap: () => openPage(context, const HelpScreen()),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _view == 0
                    ? _ListBody(
                        key: const ValueKey('list'),
                        results: results,
                        closed: closed,
                      )
                    : _MapBody(
                        key: const ValueKey('map'),
                        results: results,
                        selected: selected,
                        closed: closed,
                        onSelect: (place) => setState(() => _selectedId = place.id),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? (icon != null ? AppColors.primaryDark : AppColors.primary) : const Color(0xFFFFF4F9),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: filled ? Colors.transparent : const Color(0xFFF6C6E0)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    super.key,
    required this.results,
    required this.closed,
  });

  final List<Place> results;
  final List<Place> closed;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      if (AppScope.of(context).liveLoading) return const _LoadingResults();
      return _EmptyResults(closed: closed);
    }
    final app = AppScope.of(context);
    final bands = distanceBands(results, app.originLat, app.originLng);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (app.liveMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              app.liveMessage,
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        Text(
          '${results.length} result${results.length == 1 ? '' : 's'} · under 1 km, 1–2 km, 2–3 km, 3 km+',
          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final band in bands.where((band) => band.places.isNotEmpty)) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                Text(band.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(
                  '${band.places.length} ${band.places.length == 1 ? 'place' : 'places'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          for (var i = 0; i < band.places.length; i++) ...[
            RiseIn(
              index: i,
              child: _PlaceCard(
                place: band.places[i],
                onTap: () => openPlace(context, band.places[i]),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlacePhoto(place: place, height: 132, hero: true),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusPill(label: place.open ? 'OPEN' : 'CLOSED'),
                    if (place.free) ...[
                      const SizedBox(height: 4),
                      const StatusPill(label: 'FREE'),
                    ],
                    if (place.paid) ...[
                      const SizedBox(height: 4),
                      const StatusPill(label: 'PAID'),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      AppScope.of(context).distanceLabel(place),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(place.kindLabel, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(place.address, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            if (place.note != null) ...[
              const SizedBox(height: 2),
              Text(place.note!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in place.tags) ServiceTag(tag)],
            ),
            if (!place.open) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFF87171)),
                  const SizedBox(width: 6),
                  Text(
                    place.closedNote,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
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

class _MapBody extends StatelessWidget {
  const _MapBody({
    super.key,
    required this.results,
    required this.selected,
    required this.closed,
    required this.onSelect,
  });

  final List<Place> results;
  final Place? selected;
  final List<Place> closed;
  final ValueChanged<Place> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AnimatedFinderMap(
              pins: results,
              selectedId: selected?.id,
              onSelect: onSelect,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: selected == null
              ? AppScope.of(context).liveLoading
                  ? const _LoadingResults(key: ValueKey('loading-sheet'))
                  : _EmptySheet(key: const ValueKey('empty-sheet'), closed: closed)
              : _PlaceSheet(key: ValueKey(selected!.id), place: selected!),
        ),
      ],
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E1E4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text(
                AppScope.of(context).distanceLabel(place),
                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${place.address}${place.free ? ' · Free supplies available' : ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              StatusPill(label: place.open ? 'OPEN' : 'CLOSED'),
              if (place.free) const StatusPill(label: 'FREE'),
              if (place.paid) const StatusPill(label: 'PAID'),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'View details',
            height: 46,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => openPlace(context, place),
          ),
        ],
      ),
    );
  }
}

class _EmptySheet extends StatelessWidget {
  const _EmptySheet({super.key, required this.closed});

  final List<Place> closed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Text(
        closed.isEmpty
            ? 'No places match this search.'
            : '${closed.length} closed ${closed.length == 1 ? 'place matches' : 'places match'}. Turn off Open now to see ${closed.length == 1 ? 'it' : 'them'}.',
        style: const TextStyle(color: AppColors.muted, height: 1.4),
      ),
    );
  }
}

class _LoadingResults extends StatelessWidget {
  const _LoadingResults({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final place = app.searchQuery.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              place.isEmpty ? 'Finding pharmacies near you' : 'Finding pharmacies in $place',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.closed});

  final List<Place> closed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        RiseIn(
          index: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF6C6E0), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.blushDeep,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.explore_off_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  closed.isEmpty ? 'No places match' : 'Nothing open matches',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  closed.isEmpty
                      ? 'Try another area, name, or a wider radius.'
                      : 'Closed places are listed below. Clear Open now to include them.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Pressable(
                  onTap: () => openPage(context, const FiltersScreen(), sheet: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Adjust filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'CLOSED NEARBY',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          for (final place in closed) ...[
            Pressable(
              onTap: () => openPlace(context, place),
              child: SoftCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(place.address, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(place.closedNote, style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const StatusPill(label: 'CLOSED'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 16),
        GradientButton(
          label: 'Clear filters',
          icon: Icons.filter_alt_off_rounded,
          onPressed: () => AppScope.of(context).clearFilters(),
        ),
      ],
    );
  }
}
