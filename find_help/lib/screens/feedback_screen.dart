import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.place, this.showBack = true});

  final Place place;
  final bool showBack;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String? _experience;
  final _note = TextEditingController();
  var _done = false;
  var _loadedExisting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedExisting) return;
    _loadedExisting = true;
    final existing = AppScope.of(context).feedbackFor(widget.place.id);
    if (existing == null) return;
    _experience = existing.experience;
    _note.text = existing.note;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (widget.showBack) ...[
                    const BackButtonRound(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      'How was your visit?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLACE',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(widget.place.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.place.address} · ${AppScope.of(context).distanceLabel(widget.place)} away',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR FEEDBACK',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('How did it go?', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _Choice(
                                icon: Icons.thumb_up_alt_rounded,
                                label: 'Yes, this helped',
                                color: const Color(0xFF16A34A),
                                selected: _experience == 'helped',
                                onTap: () => setState(() => _experience = 'helped'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Choice(
                                icon: Icons.thumb_down_alt_rounded,
                                label: 'Not quite right',
                                color: const Color(0xFFDC2626),
                                selected: _experience == 'not',
                                onTap: () => setState(() => _experience = 'not'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Add a note (optional)',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _note,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Write only what you feel safe to share...',
                          ),
                        ),
                        if (_experience != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Submission ready. This helps other people find the right place.',
                                    style: TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    child: _done
                        ? const _Thanks(key: ValueKey('thanks'))
                        : GradientButton(
                            key: const ValueKey('submit'),
                            label: 'Submit feedback',
                            onPressed: _experience == null
                                ? null
                                : () {
                                    AppScope.of(context).saveFeedback(
                                      placeId: widget.place.id,
                                      experience: _experience!,
                                      note: _note.text,
                                    );
                                    setState(() => _done = true);
                                  },
                          ),
                  ),
                  if (!_done && AppScope.of(context).feedbackFor(widget.place.id) != null)
                    TextButton(
                      onPressed: () {
                        AppScope.of(context).removeFeedback(widget.place.id);
                        setState(() {
                          _experience = null;
                          _note.clear();
                          _done = false;
                        });
                        showAppSnack(context, 'Feedback deleted');
                      },
                      child: const Text('Delete saved feedback', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  if (!_done && _experience == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Choose how the visit went before submitting.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : const Color(0xFFF8F6F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : const Color(0xFFE7E2E5), width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.muted),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : const Color(0xFF666066),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 560),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 38),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Thank you',
            style: TextStyle(color: Color(0xFF166534), fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your feedback helps improve this service for everyone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF15803D), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Back to home',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
