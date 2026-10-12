import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _note = TextEditingController();
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  var _showForm = false;
  int? _editingId;
  String _kind = 'Pharmacy';
  int? _pendingDelete;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _area.addListener(_refresh);
  }

  var _refreshQueued = false;

  void _refresh() {
    if (_refreshQueued || !mounted) return;
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.removeListener(_refresh);
    _area.removeListener(_refresh);
    _name.dispose();
    _area.dispose();
    _note.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _showForm = false;
      _editingId = null;
      _kind = 'Pharmacy';
      _name.clear();
      _area.clear();
      _note.clear();
    });
  }

  void _edit(SavedPlace place) {
    setState(() {
      _editingId = place.id;
      _name.text = place.name;
      _area.text = place.area;
      _note.text = place.note;
      _kind = place.kind;
      _showForm = true;
      _pendingDelete = null;
    });
  }

  void _save() {
    final name = _name.text.trim();
    final area = _area.text.trim();
    if (name.isEmpty || area.isEmpty) return;
    final app = AppScope.of(context);
    if (_editingId == null) {
      app.addSaved(
        SavedPlace(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          area: area,
          kind: _kind,
          note: _note.text.trim(),
        ),
      );
      showAppSnack(context, 'Place added');
    } else {
      app.updateSaved(
        SavedPlace(
          id: _editingId!,
          name: name,
          area: area,
          kind: _kind,
          note: _note.text.trim(),
        ),
      );
      showAppSnack(context, 'Place updated');
    }
    _reset();
  }

  String _hours(SavedPlace place) {
    if (place.name == 'Health Guard Pharmacy') return 'Open today until 4:00 PM';
    if (place.name == 'City Community Clinic') return 'Open weekdays until 6:00 PM';
    if (place.note.isNotEmpty) return place.note;
    return 'Opening hours not provided';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.saved;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (widget.showBack) ...[
                    const BackButtonRound(),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved places', style: Theme.of(context).textTheme.displayLarge),
                        Text(
                          '${items.length} places ready for your next visit',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => _showForm ? _reset() : setState(() => _showForm = true),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE21886),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x330F766E), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (!_showForm) const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          if (!_showForm) const SizedBox(width: 4),
                          Text(
                            _showForm ? 'Cancel' : 'Add place',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
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
                  RiseIn(index: 0, child: _Summary(count: items.length, drift: _drift)),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_showForm
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _PlaceForm(
                              editing: _editingId != null,
                              name: _name,
                              area: _area,
                              note: _note,
                              kind: _kind,
                              onKind: (value) => setState(() => _kind = value),
                              onSave: _save,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All saved places', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            SizedBox(height: 2),
                            Text(
                              'Tap a place to view services and directions',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F7),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFF8C6E0)),
                        ),
                        child: Text(
                          '${items.length} total',
                          style: const TextStyle(color: Color(0xFF9F0D71), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        children: [
                          const Text('No saved places yet', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text(
                            'Add a trusted pharmacy or clinic to find it quickly later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Pressable(
                            onTap: () => setState(() => _showForm = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Add your first place',
                                style: TextStyle(color: Color(0xFF9F0D71), fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      RiseIn(
                        index: i + 1,
                        child: _SavedCard(
                          place: items[i],
                          hours: _hours(items[i]),
                          pending: _pendingDelete == items[i].id,
                          onView: () => openPlace(context, placeForSaved(items[i])),
                          onEdit: () => _edit(items[i]),
                          onAskDelete: () => setState(() => _pendingDelete = items[i].id),
                          onKeep: () => setState(() => _pendingDelete = null),
                          onDelete: () {
                            app.removeSaved(items[i].id);
                            setState(() => _pendingDelete = null);
                            showAppSnack(context, 'Place removed');
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.drift});

  final int count;
  final Animation<double> drift;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A122C), Color(0xFF9F0D71), Color(0xFFE21886)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: drift,
                builder: (context, _) {
                  final t = drift.value;
                  return Stack(
                    children: [
                      Positioned(
                        right: -20 + (12 * t),
                        top: -30 + (8 * (1 - t)),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x22FFFFFF)),
                        ),
                      ),
                      Positioned(
                        right: 48,
                        bottom: -36 + (10 * t),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR DIRECTORY',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count saved ${count == 1 ? 'place' : 'places'}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xCCFFFFFF), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Trusted locations, stored on this device',
                                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Pressable(
                  onTap: () => goTab(context, 1),
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Find another location',
                          style: TextStyle(color: Color(0xFF9F0D71), fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Color(0xFF9F0D71), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceForm extends StatelessWidget {
  const _PlaceForm({
    required this.editing,
    required this.name,
    required this.area,
    required this.note,
    required this.kind,
    required this.onKind,
    required this.onSave,
  });

  final bool editing;
  final TextEditingController name;
  final TextEditingController area;
  final TextEditingController note;
  final String kind;
  final ValueChanged<String> onKind;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ready = name.text.trim().isNotEmpty && area.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF8C6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editing ? 'Edit saved place' : 'Add a saved place',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep the details you need for a future visit.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('PLACE NAME', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: name,
            decoration: const InputDecoration(hintText: 'e.g. Central Pharmacy'),
          ),
          const SizedBox(height: 10),
          const Text('AREA OR ADDRESS', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: area,
            decoration: const InputDecoration(hintText: 'Neighbourhood or street'),
          ),
          const SizedBox(height: 10),
          const Text('TYPE', style: _label),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final option in const ['Pharmacy', 'Clinic', 'Community']) ...[
                if (option != 'Pharmacy') const SizedBox(width: 6),
                Expanded(
                  child: Pressable(
                      onTap: () => onKind(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kind == option ? const Color(0xFFE21886) : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kind == option ? const Color(0xFFE21886) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: kind == option ? Colors.white : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Text('VISIT NOTE', style: _label),
          const SizedBox(height: 6),
          TextField(
            controller: note,
            decoration: const InputDecoration(hintText: 'Hours, services, or a reminder'),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: ready ? onSave : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: ready ? 1 : 0.4,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE21886),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  editing ? 'Save changes' : 'Add to saved places',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _label = TextStyle(
  color: Color(0xFF64748B),
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
);

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.place,
    required this.hours,
    required this.pending,
    required this.onView,
    required this.onEdit,
    required this.onAskDelete,
    required this.onKeep,
    required this.onDelete,
  });

  final SavedPlace place;
  final String hours;
  final bool pending;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onAskDelete;
  final VoidCallback onKeep;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final showNote = place.note.isNotEmpty && place.note != hours;
    final known = placeByName(place.name);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: known == null
                      ? const ColoredBox(
                          color: Color(0xFFFFF1F7),
                          child: Icon(Icons.local_pharmacy_rounded, color: Color(0xFFE21886)),
                        )
                      : PlacePhoto(place: known, height: 48, radius: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F7),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0xFFF8C6E0)),
                          ),
                          child: Text(
                            place.kind.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9F0D71),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 14, color: Color(0xFFE21886)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(place.area, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        _PulseDot(),
                        SizedBox(width: 6),
                        Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFE21886)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 2),
                      child: Text(
                        hours,
                        style: const TextStyle(color: Color(0xFF9F0D71), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (showNote)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(place.note, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: pending
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Remove this saved place?',
                            style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(onPressed: onKeep, child: const Text('Keep')),
                        TextButton(
                          onPressed: onDelete,
                          child: const Text('Remove', style: TextStyle(color: Color(0xFFDC2626))),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Pressable(
                          onTap: onView,
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'View details',
                              style: TextStyle(color: Color(0xFF9F0D71), fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _IconAction(icon: Icons.edit_rounded, color: const Color(0xFF475569), onTap: onEdit),
                      const SizedBox(width: 8),
                      _IconAction(icon: Icons.delete_outline_rounded, color: const Color(0xFFDC2626), onTap: onAskDelete),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE21886),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE21886).withValues(alpha: (1 - _controller.value) * 0.45),
                blurRadius: 6,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color == const Color(0xFFDC2626) ? const Color(0xFFFEF2F2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
