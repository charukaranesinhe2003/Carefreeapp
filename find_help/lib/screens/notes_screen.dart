import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _body = TextEditingController();
  int? _editingId;
  int? _pendingDelete;

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _body.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _editingId = null;
      _title.clear();
      _place.clear();
      _body.clear();
    });
  }

  void _edit(VisitNote note) {
    setState(() {
      _editingId = note.id;
      _title.text = note.title;
      _place.text = note.place;
      _body.text = note.body;
      _pendingDelete = null;
    });
  }

  void _save() {
    final title = _title.text.trim();
    final place = _place.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || place.isEmpty) {
      showAppSnack(context, 'Add a title and a place');
      return;
    }
    final app = AppScope.of(context);
    if (_editingId == null) {
      app.addNote(
        VisitNote(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          place: place,
          body: body,
        ),
      );
      showAppSnack(context, 'Note added');
    } else {
      app.updateNote(VisitNote(id: _editingId!, title: title, place: place, body: body));
      showAppSnack(context, 'Note updated');
    }
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
                const BackButtonRound(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: Theme.of(context).textTheme.displayLarge),
                      Text('Write, edit, or delete a visit note', style: TextStyle(color: AppColors.muted, fontSize: 12)),
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
                  Text(editing ? 'Edit note' : 'Add a note', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _place,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Pharmacy or clinic'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _body,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'What to remember'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: editing ? 'Save note' : 'Add note',
                      height: 48,
                      onPressed: _save,
                    ),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlineButton(label: 'Cancel edit', height: 44, onPressed: _reset),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('${app.notes.length} notes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (app.notes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('No notes yet. Add one above.', textAlign: TextAlign.center),
              ),
            for (final note in app.notes) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF3D6E6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(note.place, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (note.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(note.body, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                    ],
                    const SizedBox(height: 8),
                    if (_pendingDelete == note.id)
                      Row(
                        children: [
                          Expanded(
                            child: OutlineButton(
                              label: 'Keep',
                              height: 44,
                              onPressed: () => setState(() => _pendingDelete = null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GradientButton(
                              label: 'Delete',
                              height: 44,
                              onPressed: () {
                                app.removeNote(note.id);
                                if (_editingId == note.id) _reset();
                                setState(() => _pendingDelete = null);
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlineButton(label: 'Edit', height: 44, onPressed: () => _edit(note)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlineButton(
                              label: 'Delete',
                              height: 44,
                              onPressed: () => setState(() => _pendingDelete = note.id),
                            ),
                          ),
                        ],
                      ),
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
