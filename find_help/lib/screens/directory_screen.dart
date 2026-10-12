import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _tags = TextEditingController();
  final _note = TextEditingController();
  var _showForm = false;
  int? _editingId;
  var _open = true;
  var _free = false;
  String _kind = 'Pharmacy';

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _address.dispose();
    _phone.dispose();
    _tags.dispose();
    _note.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _showForm = false;
      _editingId = null;
      _open = true;
      _free = false;
      _kind = 'Pharmacy';
      _name.clear();
      _area.clear();
      _address.clear();
      _phone.clear();
      _tags.clear();
      _note.clear();
    });
  }

  void _edit(ManagedPharmacy pharmacy) {
    setState(() {
      _editingId = pharmacy.id;
      _name.text = pharmacy.name;
      _area.text = pharmacy.area;
      _address.text = pharmacy.address;
      _phone.text = pharmacy.phone;
      _tags.text = pharmacy.tags.join(', ');
      _note.text = pharmacy.note;
      _open = pharmacy.open;
      _free = pharmacy.free;
      _kind = pharmacy.kind;
      _showForm = true;
    });
  }

  void _save() {
    final name = _name.text.trim();
    final area = _area.text.trim();
    if (name.isEmpty || area.isEmpty) {
      showAppSnack(context, 'Name and area are required');
      return;
    }
    final tags = _tags.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final pharmacy = ManagedPharmacy(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch,
      name: name,
      area: area,
      address: _address.text.trim().isEmpty ? area : _address.text.trim(),
      phone: _phone.text.trim(),
      open: _open,
      free: _free,
      kind: _kind,
      tags: tags.isEmpty ? ['Pads', _kind] : tags,
      note: _note.text.trim(),
    );
    final app = AppScope.of(context);
    if (_editingId == null) {
      app.addManaged(pharmacy);
      showAppSnack(context, 'Pharmacy added. It shows when you search $area.');
    } else {
      app.updateManaged(pharmacy);
      showAppSnack(context, 'Pharmacy updated');
    }
    app.setSearch(area);
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.managed;

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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My pharmacies', style: Theme.of(context).textTheme.displayLarge),
                        Text(
                          'Create, edit, and delete places stored on this phone',
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
                        _showForm ? 'Cancel' : 'Add',
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
                  if (_showForm) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId == null ? 'New pharmacy' : 'Edit pharmacy',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                          TextField(controller: _area, decoration: const InputDecoration(labelText: 'Area')),
                          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                          TextField(
                            controller: _tags,
                            decoration: const InputDecoration(labelText: 'Tags, separated by commas'),
                          ),
                          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _kind,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: const [
                              DropdownMenuItem(value: 'Pharmacy', child: Text('Pharmacy')),
                              DropdownMenuItem(value: 'Clinic', child: Text('Clinic')),
                              DropdownMenuItem(value: 'Community', child: Text('Community')),
                            ],
                            onChanged: (value) => setState(() => _kind = value ?? 'Pharmacy'),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Open now'),
                            value: _open,
                            onChanged: (value) => setState(() => _open = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Free supplies'),
                            value: _free,
                            onChanged: (value) => setState(() => _free = value),
                          ),
                          const SizedBox(height: 8),
                          GradientButton(
                            label: _editingId == null ? 'Save pharmacy' : 'Update pharmacy',
                            height: 46,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '${items.length} saved by you · search updates as soon as you save',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text(
                        'No custom pharmacies yet. Add one for an area and it will appear in search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (final pharmacy in items) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pharmacy.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            '${pharmacy.area} · ${pharmacy.address}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          if (pharmacy.note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(pharmacy.note, style: const TextStyle(fontSize: 12)),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ServiceTag(pharmacy.open ? 'OPEN' : 'CLOSED'),
                              ServiceTag(pharmacy.kind),
                              if (pharmacy.free) const ServiceTag('Free'),
                              for (final tag in pharmacy.tags.take(3)) ServiceTag(tag),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _edit(pharmacy),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Edit'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  app.removeManaged(pharmacy.id);
                                  showAppSnack(context, 'Pharmacy deleted');
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                label: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => app.setSearch(pharmacy.area),
                                child: const Text('Show nearby'),
                              ),
                            ],
                          ),
                        ],
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
