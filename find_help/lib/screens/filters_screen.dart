import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  var _ready = false;
  late double _radius;
  late String _type;
  late String _cost;
  late bool _openOnly;
  late bool _freeOnly;
  late bool _padsOnly;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final app = AppScope.of(context);
    _radius = app.radiusKm;
    _type = app.type;
    _cost = app.cost == 'Free' ? 'Any' : app.cost;
    _openOnly = app.openOnly;
    _freeOnly = app.cost == 'Free' || app.chips.contains('Free');
    _padsOnly = app.chips.contains('Pads');
    _ready = true;
  }

  List<Place> _preview(AppController app) {
    final chips = <String>{
      if (_openOnly) 'Open now',
      if (_freeOnly) 'Free',
      if (_padsOnly) 'Pads',
    };
    return app.placesFor(
      radiusKm: _radius,
      type: _type,
      cost: _freeOnly ? 'Free' : _cost,
      openOnly: _openOnly,
      chips: chips,
    );
  }

  void _apply(AppController app) {
    app.applyFilters(
      radiusKm: _radius,
      type: _type,
      cost: _freeOnly ? 'Free' : _cost,
      openOnly: _openOnly,
    );
    app.setServiceChips(free: _freeOnly, pads: _padsOnly);
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final app = AppScope.of(context);
    final preview = _preview(app);
    final town = app.searchQuery.trim().isEmpty ? app.townLabel : app.searchQuery.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filters', style: Theme.of(context).textTheme.displayLarge),
                        SizedBox(height: 2),
                        Text('Distance, open now, and what you need', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Pressable(
                    semanticLabel: 'Close filters',
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF3D6E6)),
                      ),
                      child: const Icon(Icons.close_rounded, color: AppColors.primary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  RiseIn(
                    index: 0,
                    child: _LiveCount(count: preview.length, town: town, radius: _radius),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 1,
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SectionLabel('Distance from you'),
                              const Spacer(),
                              Text(
                                '${_radius.toStringAsFixed(0)} km',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Slider(
                            value: _radius,
                            min: 1,
                            max: 25,
                            divisions: 24,
                            activeColor: AppColors.primary,
                            label: '${_radius.toStringAsFixed(0)} km',
                            onChanged: (value) => setState(() => _radius = value),
                          ),
                          const Text(
                            'Places farther than this stay hidden. Pharmacy, clinic, free, and pads each change the list.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 2,
                    child: _FilterCard(
                      title: 'Place type',
                      child: ChoiceGrid(
                        options: const ['All', 'Pharmacy', 'Clinic', 'Community'],
                        selected: _type,
                        onSelected: (value) => setState(() => _type = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 3,
                    child: _FilterCard(
                      title: 'Cost',
                      child: ChoiceGrid(
                        options: const ['Any', 'Low Cost', 'Paid'],
                        selected: _freeOnly ? 'Any' : _cost,
                        onSelected: (value) => setState(() {
                          _cost = value;
                          _freeOnly = false;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RiseIn(
                    index: 4,
                    child: SoftCard(
                      child: Column(
                        children: [
                          _SwitchRow(
                            title: 'Open now',
                            subtitle: 'Hide pharmacies that are closed',
                            value: _openOnly,
                            onChanged: (value) => setState(() => _openOnly = value),
                          ),
                          const Divider(height: 22),
                          _SwitchRow(
                            title: 'Free supplies',
                            subtitle: 'Only places that list free items',
                            value: _freeOnly,
                            onChanged: (value) => setState(() => _freeOnly = value),
                          ),
                          const Divider(height: 22),
                          _SwitchRow(
                            title: 'Pads available',
                            subtitle: 'Only places that list pads',
                            value: _padsOnly,
                            onChanged: (value) => setState(() => _padsOnly = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const SectionLabel('You will see'),
                    const SizedBox(height: 8),
                    for (final place in preview.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                            Text(place.area, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  OutlineButton(
                    label: 'Reset',
                    fill: const Color(0xFFFFF4F9),
                    onPressed: () => setState(() {
                      _radius = 5;
                      _type = 'All';
                      _cost = 'Any';
                      _openOnly = true;
                      _freeOnly = false;
                      _padsOnly = false;
                    }),
                  ),
                  const SizedBox(height: 10),
                  GradientButton(
                    label: 'Show ${preview.length} places',
                    onPressed: () => _apply(app),
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

class _LiveCount extends StatelessWidget {
  const _LiveCount({required this.count, required this.town, required this.radius});

  final int count;
  final String town;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: count.toDouble()),
            duration: const Duration(milliseconds: 420),
            builder: (context, value, _) => Text(
              value.round().toString(),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1 ? 'place within ${radius.toStringAsFixed(0)} km of $town' : 'places within ${radius.toStringAsFixed(0)} km of $town',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return const Color(0xFFE6E0E4);
          }),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
