import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  void _showAddEditDialog(BuildContext context, [Reminder? existingReminder]) {
    final titleController = TextEditingController(text: existingReminder?.title ?? '');
    TimeOfDay selectedTime = existingReminder != null
        ? TimeOfDay(hour: existingReminder.hour, minute: existingReminder.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                existingReminder == null ? 'Add Reminder' : 'Edit Reminder', 
                style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Reminder Title (e.g. Drink Water)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time: ${selectedTime.format(context)}', style: const TextStyle(fontSize: 16)),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: const Text('Change', style: TextStyle(color: AppTheme.primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    
                    if (existingReminder == null) {
                      final newReminder = Reminder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                      );
                      await ReminderService.addReminder(newReminder);
                    } else {
                      final updatedReminder = Reminder(
                        id: existingReminder.id,
                        title: titleController.text.trim(),
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                        isActive: existingReminder.isActive,
                      );
                      await ReminderService.updateReminder(updatedReminder);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Custom Reminders', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryDark),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<dynamic>('settings').listenable(),
        builder: (context, box, _) {
          final reminders = ReminderService.getReminders();
          
          if (reminders.isEmpty) {
            return const Center(
              child: Text('No reminders yet.\nTap + to create one!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textLight, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute).format(context);
              
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                  subtitle: Text(time, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: reminder.isActive,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          final updated = Reminder(
                            id: reminder.id,
                            title: reminder.title,
                            hour: reminder.hour,
                            minute: reminder.minute,
                            isActive: val,
                          );
                          ReminderService.updateReminder(updated);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.textLight),
                        onPressed: () => _showAddEditDialog(context, reminder),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => ReminderService.deleteReminder(reminder.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
