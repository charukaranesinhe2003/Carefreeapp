import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/daily_log.dart';
import '../services/daily_log_store.dart';
import '../l10n/strings.dart';
import '../l10n/lang.dart';

class DailyLoggingScreen extends StatefulWidget {
  final DateTime? date;
  const DailyLoggingScreen({super.key, this.date});

  @override
  State<DailyLoggingScreen> createState() => _DailyLoggingScreenState();
}

class _DailyLoggingScreenState extends State<DailyLoggingScreen> {
  String _selectedFlow = '';
  String _selectedSymptoms = '';
  String _selectedMood = '';
  final TextEditingController _noteController = TextEditingController();

  late DateTime _logDate;

  @override
  void initState() {
    super.initState();
    _logDate = widget.date ?? DateTime.now();
    // Load existing log if any
    final existingLog = DailyLogStore.getLogForDate(_logDate);
    if (existingLog != null) {
      _selectedFlow = existingLog.flowIntensity;
      _selectedSymptoms = existingLog.symptoms;
      _selectedMood = existingLog.mood;
      _noteController.text = existingLog.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveLog() async {
    final log = DailyLog(
      date: _logDate,
      flowIntensity: _selectedFlow,
      symptoms: _selectedSymptoms,
      mood: _selectedMood,
      note: _noteController.text,
    );
    await DailyLogStore.saveLog(log);

    if (mounted) {
      if (_activeTab == 'Flow') {
        setState(() {
          _activeTab = 'Symptoms';
        });
      } else if (_activeTab == 'Symptoms') {
        setState(() {
          _activeTab = 'Mood';
        });
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('save_entry') + ' ✅', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  void _deleteLog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Clear Data', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.clear, color: AppTheme.primaryColor),
                title: Text('Clear ${t(_activeTab.toLowerCase())} data only'),
                onTap: () {
                  Navigator.pop(context);
                  _clearCurrentTab();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear all data & notes for today', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _clearAllData();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  void _clearCurrentTab() async {
    setState(() {
      if (_activeTab == 'Flow') {
        _selectedFlow = '';
      } else if (_activeTab == 'Symptoms') {
        _selectedSymptoms = '';
      } else if (_activeTab == 'Mood') {
        _selectedMood = '';
      }
    });

    final log = DailyLog(
      date: _logDate,
      flowIntensity: _selectedFlow,
      symptoms: _selectedSymptoms,
      mood: _selectedMood,
      note: _noteController.text,
    );
    await DailyLogStore.saveLog(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t(_activeTab.toLowerCase())} Cleared 🗑️', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  void _clearAllData() async {
    setState(() {
      _selectedFlow = '';
      _selectedSymptoms = '';
      _selectedMood = '';
      _noteController.text = '';
    });

    await DailyLogStore.deleteLog(_logDate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared 🗑️', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  String _activeTab = 'Flow';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(
      valueListenable: LangService.current,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Log for ${_logDate.day}/${_logDate.month}', style: const TextStyle(color: AppTheme.textDark)),
            backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteLog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('how_feeling'), style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLogCategory(t('flow'), Icons.water_drop, _activeTab == 'Flow', () => setState(() => _activeTab = 'Flow')),
                _buildLogCategory(t('symptoms'), Icons.favorite, _activeTab == 'Symptoms', () => setState(() => _activeTab = 'Symptoms')),
                _buildLogCategory(t('mood'), Icons.mood, _activeTab == 'Mood', () => setState(() => _activeTab = 'Mood')),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
              child: _buildActiveTabContent(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5))),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                child: Text(t('save_entry')),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text(t('data_private'), style: const TextStyle(color: AppTheme.textLight))),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeTab == 'Flow') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('flow_intensity'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPill('Light', _selectedFlow, (val) => setState(() => _selectedFlow = val)), 
              _buildPill('Medium', _selectedFlow, (val) => setState(() => _selectedFlow = val)), 
              _buildPill('Heavy', _selectedFlow, (val) => setState(() => _selectedFlow = val)), 
              _buildPill('Spotting', _selectedFlow, (val) => setState(() => _selectedFlow = val)),
            ],
          ),
        ],
      );
    } else if (_activeTab == 'Symptoms') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('symptoms_caps'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPill('Cramps', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
              _buildPill('Bloating', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
              _buildPill('Headache', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
              _buildPill('Fatigue', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
              _buildPill('Tender', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
              _buildPill('Nausea', _selectedSymptoms, (val) => setState(() => _selectedSymptoms = val)),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('mood_today'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPill('Calm', _selectedMood, (val) => setState(() => _selectedMood = val)),
              _buildPill('Anxious', _selectedMood, (val) => setState(() => _selectedMood = val)),
              _buildPill('Sad', _selectedMood, (val) => setState(() => _selectedMood = val)),
              _buildPill('Irritable', _selectedMood, (val) => setState(() => _selectedMood = val)),
              _buildPill('Tired', _selectedMood, (val) => setState(() => _selectedMood = val)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildLogCategory(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3), width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, 
              radius: 25, 
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600)
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryColor : AppTheme.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String key, String currentValue, Function(String) onSelect) {
    bool isSelected = currentValue == key;
    return GestureDetector(
      onTap: () {
        // Toggle off if already selected, otherwise select
        onSelect(isSelected ? '' : key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
        child: Text(
          t(key), 
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )
        ),
      ),
    );
  }
}
