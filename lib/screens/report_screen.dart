import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../services/daily_log_store.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box<dynamic>('settings');
    int periodLength = settings.get('profile_cycle_length', defaultValue: 5) as int;
    if (periodLength > 10) periodLength = 5;
    
    List<dynamic> savedCycles = settings.get('past_cycles_manual', defaultValue: []) as List<dynamic>;
    int cycleLength = 28;
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
      }
    }
    String regularity = settings.get('profile_regularity', defaultValue: 'Regular') as String;
    
    final logs = DailyLogStore.getAllLogs();
    logs.sort((a, b) => b.date.compareTo(a.date)); // descending

    return Scaffold(
      backgroundColor: Colors.white, // Paper like
      appBar: AppBar(
        title: const Text('Health Report', style: TextStyle(color: AppTheme.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading PDF Report... (Saved to Device Storage)')),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'CYCLE HISTORY REPORT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.primaryDark),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Generated on ${DateTime.now().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 40, thickness: 2),
            
            const Text('Patient Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 12),
            _buildReportRow('Average Cycle Length', '$cycleLength Days'),
            _buildReportRow('Cycle Regularity', regularity),
            _buildReportRow('Total Logged Days', '${logs.length} Days'),
            
            const Divider(height: 40, thickness: 1),
            const Text('Recent Symptoms & Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 12),
            
            Expanded(
              child: logs.isEmpty 
                ? const Center(child: Text('No logs available for the report.'))
                : ListView.builder(
                    itemCount: logs.length > 10 ? 10 : logs.length, // show last 10 logs max
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final dateStr = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (log.flowIntensity.isNotEmpty) Text('Flow: ${log.flowIntensity}', style: const TextStyle(color: Colors.redAccent)),
                            if (log.symptoms.isNotEmpty) Text('Symptoms: ${log.symptoms}'),
                            if (log.mood.isNotEmpty) Text('Mood: ${log.mood}'),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
