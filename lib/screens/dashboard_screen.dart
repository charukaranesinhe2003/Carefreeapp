import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../services/daily_log_store.dart';
import '../models/daily_log.dart';
import '../l10n/strings.dart';
import 'initial_onboarding_screen.dart';
import 'pin_setup_screen.dart';
import 'profile_setup_screen.dart';
import 'reminders_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('overview'), style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('tab_dashboard'), style: Theme.of(context).textTheme.displayLarge),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.alarm, color: AppTheme.textLight),
                          tooltip: 'Custom Reminders',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.password, color: AppTheme.textLight),
                          tooltip: t('change_pin') ?? 'Change PIN',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen(isChangingPin: true)));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.person, color: AppTheme.textLight),
                          tooltip: 'Profile Setup',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 1. Countdown Card (Realistic Data from Hive)
                ValueListenableBuilder(
                  valueListenable: Hive.box<dynamic>('settings').listenable(),
                  builder: (context, settingsBox, _) {
                    return ValueListenableBuilder<Box<DailyLog>>(
                      valueListenable: DailyLogStore.listenToLogs(),
                      builder: (context, logsBox, _) {
                        
                        // 1. Get baseline from settings
                        final startDateMs = settingsBox.get('profile_start_date') as int?;
                        // Calculate dynamic cycle length from history
                        List<dynamic> savedCycles = settingsBox.get('past_cycles_manual', defaultValue: []) as List<dynamic>;
                        int standardCycleLength = 28; // fallback
                        if (savedCycles.isNotEmpty) {
                          int sum = 0;
                          int count = 0;
                          for (var val in savedCycles) {
                            int cycle = val as int;
                            if (cycle > 0) {
                              sum += cycle;
                              count++;
                            }
                          }
                          if (count > 0) {
                            standardCycleLength = (sum / count).round();
                          }
                        }

                        DateTime? lastPeriodStart;
                        if (startDateMs != null) {
                          lastPeriodStart = DateTime.fromMillisecondsSinceEpoch(startDateMs);
                        }

                        // 2. Override with the most recent actual logged flow
                        final logs = DailyLogStore.getAllLogs();
                        logs.sort((a, b) => b.date.compareTo(a.date)); // descending
                        for (var log in logs) {
                          if (log.flowIntensity.isNotEmpty) {
                            if (lastPeriodStart == null || log.date.isAfter(lastPeriodStart)) {
                              lastPeriodStart = log.date;
                              break;
                            }
                          }
                        }

                        // 3. Calculate days left
                        String daysLeftText = '--';
                        String subtitleText = t('please_setup_profile');
                        
                        if (lastPeriodStart != null) {
                          final today = DateTime.now();
                          final todayMidnight = DateTime(today.year, today.month, today.day);
                          final lastStartMidnight = DateTime(lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);
                          
                          // How many days since the last period started?
                          final daysSince = todayMidnight.difference(lastStartMidnight).inDays;
                          
                          // How many days left in the current cycle?
                          int daysLeft = standardCycleLength - (daysSince % standardCycleLength);
                          
                          if (daysLeft == standardCycleLength) {
                            daysLeft = 0; // Today is the day
                          }

                          daysLeftText = '$daysLeft';
                          
                          if (daysLeft == 0) {
                            subtitleText = t('period_expected_today');
                          } else if (daysLeft <= 5) {
                            subtitleText = t('pms_symptoms');
                          } else if (daysLeft >= 10 && daysLeft <= 16) {
                            subtitleText = t('fertile_window');
                          } else {
                            subtitleText = t('low_chance_pregnant');
                          }
                        }

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, Color(0xFFF493AC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              )
                            ]
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.white, size: 40),
                              const SizedBox(height: 16),
                              Text(
                                t('period_starts_in'),
                                style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(daysLeftText, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(t('days'), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(subtitleText, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      }
                    );
                  }
                ),
                const SizedBox(height: 24),
                
                // Daily Insights / Tips Card (Reads from Hive Database)
                ValueListenableBuilder<Box<DailyLog>>(
                  valueListenable: DailyLogStore.listenToLogs(),
                  builder: (context, box, child) {
                    final todayLog = DailyLogStore.getLogForDate(DateTime.now());
                    String title = 'Daily Insight';
                    String message = 'Stay hydrated! Drinking water helps reduce bloating during this phase of your cycle.';
                    
                    if (todayLog != null && (todayLog.note.isNotEmpty || todayLog.flowIntensity.isNotEmpty)) {
                      title = 'Today\'s Logged Info';
                      String parts = '';
                      if (todayLog.flowIntensity.isNotEmpty) parts += 'Flow: ${todayLog.flowIntensity}. ';
                      if (todayLog.note.isNotEmpty) parts += 'Note: ${todayLog.note}';
                      message = parts;
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2), // Very light pink/red background
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(message, 
                                  style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),

                // 2. Monthly Summaries / Graphs
                ValueListenableBuilder(
                  valueListenable: Hive.box<dynamic>('settings').listenable(),
                  builder: (context, settingsBox, _) {
                    int periodLength = settingsBox.get('profile_cycle_length', defaultValue: 5) as int;
                    if (periodLength > 10) periodLength = 5;
                    int cycleLength = 28; // Standard average cycle length
                    
                    final now = DateTime.now();
                    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    
                    // Fetch real logs with flow
                    final logs = DailyLogStore.getAllLogs().where((l) => l.flowIntensity.isNotEmpty).toList();
                    logs.sort((a, b) => a.date.compareTo(b.date));

                    List<Widget> chartColumns = [];
                    int sum = 0;
                    int count = 0;
                    
                    // 1. Try to use real logged dates first
                    if (logs.length >= 2) {
                      for (int i = 1; i < logs.length; i++) {
                        final prevDate = logs[i-1].date;
                        final currDate = logs[i].date;
                        final diff = currDate.difference(prevDate).inDays;
                        if (diff > 15) {
                          sum += diff;
                          count++;
                          final monthName = monthNames[currDate.month - 1];
                          chartColumns.add(_buildBarChartColumn(monthName, diff, 40));
                        }
                      }
                    } 
                    
                    // 2. If no real logs, use manual past history entered by the user
                    if (chartColumns.isEmpty) {
                      List<dynamic> savedCycles = settingsBox.get('past_cycles_manual', defaultValue: []) as List<dynamic>;
                      if (savedCycles.length == 5) {
                        for (int i = 4; i >= 0; i--) {
                          final targetMonth = DateTime(now.year, now.month - i, 1);
                          final monthName = monthNames[targetMonth.month - 1];
                          int length = savedCycles[4 - i] as int;
                          if (length > 0) {
                            sum += length;
                            count++;
                            chartColumns.add(_buildBarChartColumn(monthName, length, 35));
                          }
                        }
                      }
                    }
                    
                    String displayAverage = 'N/A';
                    if (count > 0) {
                      displayAverage = '${(sum / count).round()} ${t('days')}';
                    }
                    
                    if (chartColumns.length > 5) {
                      chartColumns = chartColumns.sublist(chartColumns.length - 5);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('cycle_history'), style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ]
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t('average_cycle'), style: const TextStyle(color: AppTheme.textLight, fontSize: 16)),
                                  Text(displayAverage, style: const TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: chartColumns,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Generate Cycle Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartColumn(String month, int length, int maxLength) {
    double heightFactor = length / maxLength;
    return Column(
      children: [
        Text('$length', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 30,
            height: (120 * heightFactor) * 0.2, // Simulate period days
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(month, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
      ],
    );
  }
}
