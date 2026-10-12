import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/metrics_service.dart';
import '../theme/app_theme.dart';

/// Small debug overlay shown during user testing (`--dart-define=TEST_MODE=true`).
///
/// Features:
/// 1. Floating draggable badge showing live tap count and test status.
/// 2. Modal dashboard with live metrics: time-on-task, tap count, HIDE latency, error counts.
/// 3. "Start/Reset Session" button.
/// 4. "Export JSON" button that copies the JSON report to the clipboard.
/// 5. Automatically hidden when [MetricsService.isEnabled] is false.
class TestModeOverlay extends StatefulWidget {
  const TestModeOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<TestModeOverlay> createState() => _TestModeOverlayState();
}

class _TestModeOverlayState extends State<TestModeOverlay> {
  Offset _badgePosition = const Offset(16, 80);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MetricsService.instance,
      builder: (context, _) {
        if (!MetricsService.instance.isEnabled) {
          return widget.child;
        }

        return Stack(
          children: [
            widget.child,
            Positioned(
              left: _badgePosition.dx,
              top: _badgePosition.dy,
              child: GestureDetector(
                key: const Key('test_mode_drag_detector'),
                onPanUpdate: (details) {
                  setState(() {
                    _badgePosition += details.delta;
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showMetricsDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF14E80),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TEST • ${MetricsService.instance.postUnlockTapCount} taps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMetricsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final metrics = MetricsService.instance;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'User Testing Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D142C),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Metrics summary grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metricCard(
                        'Taps (Post-Unlock)',
                        '${metrics.postUnlockTapCount}',
                        'Target: <= 4',
                      ),
                      _metricCard(
                        'Time on Task',
                        metrics.timeOnTaskMs != null
                            ? '${(metrics.timeOnTaskMs! / 1000).toStringAsFixed(1)}s'
                            : 'In progress',
                        'Unlock -> HIDE',
                      ),
                      _metricCard(
                        'HIDE Latency',
                        metrics.hideLatencyMs != null
                            ? '${metrics.hideLatencyMs}ms'
                            : 'N/A',
                        'Target: < 2s',
                      ),
                      _metricCard(
                        'PIN Errors',
                        '${metrics.pinErrorCount}',
                        'Wrong attempts',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Task Success badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: metrics.taskSuccess
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          metrics.taskSuccess
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded,
                          color: metrics.taskSuccess
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          metrics.taskSuccess
                              ? 'Task Completed Successfully'
                              : 'Task in progress...',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: metrics.taskSuccess
                                ? const Color(0xFF065F46)
                                : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Session'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            metrics.startSession();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Export JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            final json = metrics.exportJson();
                            Clipboard.setData(ClipboardData(text: json));
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Metrics JSON copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(String label, String value, String sub) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
