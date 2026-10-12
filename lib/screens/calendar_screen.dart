import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import 'daily_logging_screen.dart';
import '../widgets/past_history_dialog.dart';
import '../services/daily_log_store.dart';
import '../models/daily_log.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CYCLE TRACKER', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text('My Cycle', style: Theme.of(context).textTheme.displayLarge),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: Hive.box<dynamic>('settings').listenable(),
                builder: (context, box, _) {
                  int periodLength = box.get('profile_cycle_length', defaultValue: 5) as int;
                  if (periodLength > 10) periodLength = 5; // Sanity check
                  
                  // Calculate dynamic cycle length from history
                  List<dynamic> savedCycles = box.get('past_cycles_manual', defaultValue: []) as List<dynamic>;
                  int cycleLength = 28; // Standard cycle length fallback
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
                      cycleLength = (sum / count).round();
                      if (cycleLength < 15) {
                        cycleLength = 28; // Fallback if user accidentally entered period length
                      }
                    }
                  }
                  
                  int? startMs = box.get('profile_start_date') as int?;
                  
                  DateTime now = DateTime.now();
                  DateTime today = DateTime(now.year, now.month, now.day);
                  
                  DateTime lastPeriod;
                  if (startMs != null) {
                    DateTime dt = DateTime.fromMillisecondsSinceEpoch(startMs);
                    lastPeriod = DateTime(dt.year, dt.month, dt.day);
                  } else {
                    lastPeriod = today.subtract(const Duration(days: 18));
                  }
                  
                  // Override with the most recent actual logged flow
                  final logs = DailyLogStore.getAllLogs();
                  logs.sort((a, b) => b.date.compareTo(a.date)); // Newest first
                  
                  DateTime? latestFlowDate;
                  for (var log in logs) {
                    if (log.flowIntensity.isNotEmpty) {
                      if (log.date.isAfter(lastPeriod)) {
                        latestFlowDate = DateTime(log.date.year, log.date.month, log.date.day);
                        break;
                      }
                    }
                  }
                  
                  if (latestFlowDate != null) {
                    // Walk backwards to find the true start date of this period
                    DateTime walkDate = latestFlowDate;
                    while (true) {
                      DateTime prevDay = walkDate.subtract(const Duration(days: 1));
                      bool hasFlow = logs.any((l) => 
                        l.date.year == prevDay.year && 
                        l.date.month == prevDay.month && 
                        l.date.day == prevDay.day && 
                        l.flowIntensity.isNotEmpty
                      );
                      if (hasFlow) {
                        walkDate = prevDay;
                      } else {
                        break;
                      }
                    }
                    lastPeriod = walkDate;
                  }
                  
                  // Calculate days
                  int currentDay = today.difference(lastPeriod).inDays + 1;
                  
                  // Wrap current day if it exceeds cycle length (simulate past cycles)
                  while (currentDay > cycleLength && today.isAfter(lastPeriod)) {
                    lastPeriod = lastPeriod.add(Duration(days: cycleLength));
                    currentDay = today.difference(lastPeriod).inDays + 1;
                  }
                  
                  DateTime nextPeriod = lastPeriod.add(Duration(days: cycleLength));
                  int daysUntilNext = nextPeriod.difference(today).inDays;
                  if (daysUntilNext < 0) daysUntilNext = 0;

                  // High Chance Window (usually day 11 to 16)
                  DateTime highChanceStart = lastPeriod.add(const Duration(days: 10));
                  DateTime highChanceEnd = lastPeriod.add(const Duration(days: 15));

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppTheme.primaryColor, width: 4)),
                              child: Center(child: Text('Day\n$currentDay', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 12))),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CURRENT CYCLE', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                Text('Day $currentDay of $cycleLength', style: Theme.of(context).textTheme.titleLarge),
                                Text('Next period in $daysUntilNext days', style: const TextStyle(color: AppTheme.primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Insights Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                daysUntilNext <= 3 
                                  ? 'Your period is approaching soon. Stay prepared!'
                                  : 'Your cycle is looking steady and regular.',
                                style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Calendar Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor, 'Period'),
                            const SizedBox(width: 16),
                            _buildLegendItem(AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.5), 'Next Period'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyLoggingScreen()));
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.3), shape: BoxShape.circle),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) => _buildDayMarker(day, lastPeriod, cycleLength, periodLength, false),
                          todayBuilder: (context, day, focusedDay) => _buildDayMarker(day, lastPeriod, cycleLength, periodLength, true),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const PastHistoryDialog(),
                    );
                  },
                  icon: const Icon(Icons.history, color: AppTheme.primaryColor),
                  label: const Text('Add Past Cycle History', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color fillColor, Color borderColor, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle, border: Border.all(color: borderColor))),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
      ],
    );
  }

  Widget? _buildDayMarker(DateTime day, DateTime lastPeriod, int cycleLength, int periodLength, bool isToday) {
    DateTime nDay = DateTime(day.year, day.month, day.day);
    if (nDay.isBefore(lastPeriod)) {
      if (isToday) return _buildCalendarDay(day, AppTheme.primaryColor.withOpacity(0.1), AppTheme.textDark, isToday: true);
      return null;
    }
    
    int daysSinceLastPeriod = nDay.difference(lastPeriod).inDays;
    int cycleCount = daysSinceLastPeriod ~/ cycleLength;
    int cycleDay = (daysSinceLastPeriod % cycleLength) + 1;
    
    // Period days
    if (cycleDay >= 1 && cycleDay <= periodLength) {
      if (cycleCount == 0) {
        return _buildCalendarDay(day, AppTheme.primaryColor.withOpacity(0.6), Colors.white, isToday: isToday);
      } else {
        return _buildCalendarDay(day, AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryDark, isToday: isToday);
      }
    }
    
    if (isToday) return _buildCalendarDay(day, AppTheme.primaryColor.withOpacity(0.1), AppTheme.textDark, isToday: true);
    return null;
  }

  Widget _buildCalendarDay(DateTime day, Color bgColor, Color textColor, {bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor, 
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: Colors.black26, width: 1.5) : null,
      ),
      child: Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
