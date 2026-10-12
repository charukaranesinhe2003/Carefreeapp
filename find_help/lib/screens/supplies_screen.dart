import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';

class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  var _showForm = false;
  int? _editingId;
  SupplyPriority _priority = SupplyPriority.routine;
  int? _pendingDelete;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _quantity.addListener(_refresh);
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
    _quantity.removeListener(_refresh);
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _showForm = false;
      _editingId = null;
      _priority = SupplyPriority.routine;
      _name.clear();
      _quantity.clear();
    });
  }

  void _edit(SupplyItem item) {
    setState(() {
      _editingId = item.id;
      _name.text = item.name;
      _quantity.text = item.quantity;
      _priority = item.priority;
      _showForm = true;
      _pendingDelete = null;
    });
  }

  void _save() {
    final name = _name.text.trim();
    final quantity = _quantity.text.trim();
    if (name.isEmpty || quantity.isEmpty) return;
    final app = AppScope.of(context);
    if (_editingId == null) {
      app.addSupply(
        SupplyItem(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          quantity: quantity,
          priority: _priority,
          found: false,
        ),
      );
      showAppSnack(context, 'Item added');
    } else {
      final current = app.supplies.firstWhere((item) => item.id == _editingId);
      app.updateSupply(
        current.copyWith(name: name, quantity: quantity, priority: _priority),
      );
      showAppSnack(context, 'Item updated');
    }
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.supplies;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F9),
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
                        Text('Supply Readiness', style: Theme.of(context).textTheme.displayLarge),
                        Text(
                          'Track essentials before a pharmacy visit in Sri Lanka',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => _showForm ? _reset() : setState(() => _showForm = true),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _showForm ? 'Cancel' : 'Add item',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
                    child: SoftCard(
                      child: Row(
                        children: [
                          _ProgressRing(value: app.supplyProgress),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VISIT READINESS',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${app.foundSupplies} of ${items.length} found',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: app.supplyProgress),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) {
                                      return LinearProgressIndicator(
                                        value: value,
                                        minHeight: 8,
                                        backgroundColor: const Color(0xFFF3E6EE),
                                        color: AppColors.primary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_showForm
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _SupplyForm(
                              editing: _editingId != null,
                              name: _name,
                              quantity: _quantity,
                              priority: _priority,
                              onPriority: (value) => setState(() => _priority = value),
                              onSave: _save,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'YOUR ESSENTIALS',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Pressable(
                        onTap: () => goTab(context, 1),
                        child: const Text(
                          'Find nearby',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF6C6E0)),
                      ),
                      child: Column(
                        children: [
                          const Text('Your list is clear', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text(
                            'Add supplies to prepare for your next pharmacy visit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Pressable(
                            onTap: () => setState(() => _showForm = true),
                            child: const Text(
                              'Add an item',
                              style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < items.length; i++) ...[
                      RiseIn(
                        index: i + 1,
                        child: _SupplyCard(
                          item: items[i],
                          pending: _pendingDelete == items[i].id,
                          onToggle: () => app.toggleFound(items[i].id),
                          onEdit: () => _edit(items[i]),
                          onAskDelete: () => setState(() => _pendingDelete = items[i].id),
                          onKeep: () => setState(() => _pendingDelete = null),
                          onDelete: () {
                            app.removeSupply(items[i].id);
                            setState(() => _pendingDelete = null);
                          },
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _RingPainter(animated),
            child: Center(
              child: Text(
                '${(animated * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final background = Paint()
      ..color = const Color(0xFFF3E4EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9F0D71), Color(0xFFFF4B9A)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, background);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.value != value;
}

class _SupplyForm extends StatelessWidget {
  const _SupplyForm({
    required this.editing,
    required this.name,
    required this.quantity,
    required this.priority,
    required this.onPriority,
    required this.onSave,
  });

  final bool editing;
  final TextEditingController name;
  final TextEditingController quantity;
  final SupplyPriority priority;
  final ValueChanged<SupplyPriority> onPriority;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ready = name.text.trim().isNotEmpty && quantity.text.trim().isNotEmpty;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editing ? 'Edit supply' : 'Add an essential',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Skip personal or prescription details.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(hintText: 'e.g. Hygiene supplies'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: quantity,
            decoration: const InputDecoration(hintText: 'e.g. 2 packs'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final option in SupplyPriority.values) ...[
                if (option != SupplyPriority.routine) const SizedBox(width: 6),
                Expanded(
                  child: Pressable(
                      onTap: () => onPriority(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: priority == option ? _priorityColor(option).background : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: priority == option ? _priorityColor(option).foreground : const Color(0xFFE7E2E5),
                          ),
                        ),
                        child: Text(
                          _priorityLabel(option),
                          style: TextStyle(
                            color: priority == option ? _priorityColor(option).foreground : AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: editing ? 'Save changes' : 'Add to supply list',
            onPressed: ready ? onSave : null,
          ),
        ],
      ),
    );
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({
    required this.item,
    required this.pending,
    required this.onToggle,
    required this.onEdit,
    required this.onAskDelete,
    required this.onKeep,
    required this.onDelete,
  });

  final SupplyItem item;
  final bool pending;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onAskDelete;
  final VoidCallback onKeep;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tone = _priorityColor(item.priority);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: item.found ? 0.72 : 1,
      child: SoftCard(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pressable(
                  semanticLabel: item.found ? 'Mark as needed' : 'Mark as found',
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.found ? const Color(0xFF10B981) : AppColors.card,
                      border: Border.all(
                        color: item.found ? const Color(0xFF10B981) : const Color(0xFFF6C6E0),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: item.found ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                decoration: item.found ? TextDecoration.lineThrough : null,
                                color: item.found ? AppColors.muted : AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tone.background,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: tone.foreground.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _priorityLabel(item.priority).toUpperCase(),
                              style: TextStyle(
                                color: tone.foreground,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} · ${item.found ? 'Found' : 'Still needed'}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: pending
                  ? Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Delete this item?',
                            style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(onPressed: onKeep, child: const Text('Keep')),
                        TextButton(
                          onPressed: onDelete,
                          child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: onEdit, child: const Text('Edit')),
                        TextButton(
                          onPressed: onAskDelete,
                          child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
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

class _Tone {
  const _Tone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

_Tone _priorityColor(SupplyPriority priority) {
  return switch (priority) {
    SupplyPriority.urgent => const _Tone(Color(0xFFFEF2F2), Color(0xFFDC2626)),
    SupplyPriority.soon => const _Tone(Color(0xFFFFFBEB), Color(0xFFB45309)),
    SupplyPriority.routine => const _Tone(Color(0xFFEFF6FF), Color(0xFF2563EB)),
  };
}

String _priorityLabel(SupplyPriority priority) {
  return switch (priority) {
    SupplyPriority.urgent => 'Urgent',
    SupplyPriority.soon => 'Soon',
    SupplyPriority.routine => 'Routine',
  };
}
