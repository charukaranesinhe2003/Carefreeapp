import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../l10n/lang.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import '../widgets/pill_button.dart';
import 'initial_onboarding_screen.dart';
import '../services/daily_log_store.dart';
import '../services/local_storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _selectedLength = 5;
  String _regularity = 'Regular';
  DateTime? _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final box = Hive.box<dynamic>('settings');
    if (box.containsKey('profile_cycle_length')) {
      _selectedLength = box.get('profile_cycle_length', defaultValue: 5) as int;
    }
    if (box.containsKey('profile_regularity')) {
      _regularity = box.get('profile_regularity', defaultValue: 'Regular') as String;
    }
    if (box.containsKey('profile_start_date')) {
      int? ms = box.get('profile_start_date') as int?;
      if (ms != null) {
        _startDate = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
  }

  void _deleteProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text('What would you like to reset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final box = Hive.box<dynamic>('settings');
              await box.delete('profile_cycle_length');
              await box.delete('profile_regularity');
              await box.delete('profile_start_date');
              setState(() {
                _selectedLength = 5;
                _regularity = 'Regular';
                _startDate = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form data reset successfully.')),
                );
              }
            },
            child: const Text('Reset Form'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog first
              await Hive.box<dynamic>('settings').clear();
              await DailyLogStore.clearAll();
              await LocalStorageService.clearAll();
              
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const InitialOnboardingScreen()), 
                  (route) => false
                );
              }
            },
            child: const Text('Reset Entire App', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _onFinish() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your last period start date')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Open settings box
      final box = await Hive.openBox<dynamic>('settings');
      
      // Save profile data (CRUD - Create/Update)
      await box.put('profile_cycle_length', _selectedLength);
      await box.put('profile_regularity', _regularity);
      await box.put('profile_start_date', _startDate!.millisecondsSinceEpoch);

      if (mounted) {
        // Navigates to main screen and clears stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile.')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(valueListenable: LangService.current, builder: (context, lang, _) { return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let\'s build your\ncalendar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'LAST PERIOD START DATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDate == null ? t('select_date') : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _startDate == null ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDate = DateTime.now().subtract(const Duration(days: 14));
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estimated start date set to 14 days ago.')),
                  );
                },
                child: const Text(
                  'I can\'t remember',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'AVERAGE PERIOD LENGTH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How many days does your period usually last?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final val in [3, 4, 5, 6, 7])
                    GestureDetector(
                      onTap: () => setState(() => _selectedLength = val),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _selectedLength == val ? AppTheme.primaryDark : AppTheme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedLength == val ? AppTheme.primaryDark : AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            val == 7 ? '7+' : '$val',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedLength == val ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              
              const Text(
                'CYCLE REGULARITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: t('regular'),
                      style: _regularity == 'Regular' ? PillButtonStyle.primary : PillButtonStyle.outline,
                      onPressed: () => setState(() => _regularity = 'Regular'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PillButton(
                      label: t('irregular'),
                      style: _regularity == 'Irregular' ? PillButtonStyle.primary : PillButtonStyle.outline,
                      onPressed: () => setState(() => _regularity = 'Irregular'),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Finish',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
