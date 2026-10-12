import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _title = TextEditingController();
  final _place = TextEditingController();
  int? _editingId;
  int? _pendingDelete;
  late DateTime _when;

  @override
  void initState() {
    super.initState();
    _when = _defaultWhen();
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    super.dispose();
  }

  DateTime _defaultWhen() {
    final next = DateTime.now().add(const Duration(hours: 1));
    return DateTime(next.year, next.month, next.day, next.hour, next.minute);
  }

  void _reset() {
    setState(() {
      _editingId = null;
      _title.clear();
      _place.clear();
      _when = _defaultWhen();
      _pendingDelete = null;
    });
  }

  void _edit(Reminder reminder) {
    setState(() {
      _editingId = reminder.id;
      _title.text = reminder.title;
      _place.text = reminder.place;
      _when = reminder.at ?? _defaultWhen();
      _pendingDelete = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _when = DateTime(picked.year, picked.month, picked.day, _when.hour, _when.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (picked == null) return;
    setState(() {
      _when = DateTime(_when.year, _when.month, _when.day, picked.hour, picked.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppSnack(context, 'Add what you want to be reminded about');
      return;
    }
    if (!_when.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))) {
      showAppSnack(context, 'Pick a time that is still ahead');
      return;
    }
    final app = AppScope.of(context);
    final reminder = Reminder(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      place: _place.text.trim(),
      when: formatReminderWhen(_when),
      atMillis: _when.millisecondsSinceEpoch,
    );
    final ready = _editingId == null ? await app.addReminder(reminder) : await app.updateReminder(reminder);
    if (!mounted) return;
    showAppSnack(
      context,
      ready
          ? 'Reminder set. Your phone will sound at ${formatReminderWhen(_when)}.'
          : 'Reminder saved. Allow notifications and alarms so your phone can sound.',
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final editing = _editingId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                BackButtonRound(),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reminders', style: Theme.of(context).textTheme.displayLarge),
                      Text('Pick a date and time. Due alerts show while the app is open.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF3D6E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(editing ? 'Edit reminder' : 'New reminder', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'What to remember'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _place,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Pharmacy or clinic (optional)'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your phone plays a sound and shows a notification at this time, even if the app is closed.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.calendar_today_rounded,
                          label: formatReminderWhen(_when).split(' · ').first,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.schedule_rounded,
                          label: formatReminderWhen(_when).split(' · ').last,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: editing ? 'Save reminder' : 'Add reminder',
                      height: 48,
                      onPressed: _save,
                    ),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlineButton(label: 'Cancel edit', onPressed: _reset),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('${app.reminders.length} reminders', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (app.reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('No reminders yet. Add one above.', textAlign: TextAlign.center),
              ),
            for (final reminder in app.reminders) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: reminder.isDue ? AppColors.primary : const Color(0xFFF3D6E6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        _StatusChip(label: reminder.status, due: reminder.isDue, done: reminder.done),
                      ],
                    ),
                    if (reminder.place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(reminder.place, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      reminder.at == null ? 'No time set yet. Tap Edit and choose a date.' : reminder.when,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    if (_pendingDelete == reminder.id)
                      Row(
                        children: [
                          Expanded(child: OutlineButton(label: 'Keep', height: 44, onPressed: () => setState(() => _pendingDelete = null))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GradientButton(
                              label: 'Delete',
                              height: 44,
                              onPressed: () {
                                app.removeReminder(reminder.id);
                                if (_editingId == reminder.id) _reset();
                                setState(() => _pendingDelete = null);
                              },
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(child: OutlineButton(label: 'Edit', height: 44, onPressed: () => _edit(reminder))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlineButton(
                              label: 'Delete',
                              height: 44,
                              onPressed: () => setState(() => _pendingDelete = reminder.id),
                            ),
                          ),
                        ],
                      ),
                      if (!reminder.done && reminder.at != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            label: reminder.isDue ? 'Snooze 10 minutes' : 'Mark done',
                            height: 44,
                            onPressed: () => reminder.isDue ? app.snoozeReminder(reminder.id) : app.completeReminder(reminder.id),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF6C6E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.due, required this.done});

  final String label;
  final bool due;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF15803D) : due ? AppColors.primary : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
