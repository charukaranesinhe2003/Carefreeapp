import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../content/content_repository.dart';
import '../content/content_types.dart';
import '../l10n/lang.dart';
import '../l10n/strings.dart';
import '../routes.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/hide_button.dart';
import '../widgets/lang_builder.dart';
import 'main_screen.dart';

/// Single record for a completed quiz attempt.
class QuizScoreRecord {
  const QuizScoreRecord({
    required this.score,
    required this.total,
    required this.date,
  });

  final int score;
  final int total;
  final DateTime date;

  Map<String, dynamic> toMap() => {
    'score': score,
    'total': total,
    'timestamp': date.millisecondsSinceEpoch,
  };

  factory QuizScoreRecord.fromMap(Map<dynamic, dynamic> map) {
    final score = (map['score'] as num?)?.toInt() ?? 0;
    final total = (map['total'] as num?)?.toInt() ?? 5;
    final ms = (map['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    return QuizScoreRecord(
      score: score,
      total: total,
      date: DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}

/// S7 – Myth Buster quiz screen (REQ-3.1, REQ-3.2).
///
/// Features:
/// 1. Dark maroon theme with [AppTopBar] (dark mode) and panic [HideButton].
/// 2. Header progress indicator with "QUESTION N OF TOTAL" label.
/// 3. White question card with "?" badge, cultural saying statement in quotes,
///    and sub-prompt "Is this cultural saying true or false?".
/// 4. Stacked response buttons: "It's a MYTH" and "It's a FACT".
/// 5. Feedback card on answer with correct/incorrect badge, explanation, and "Next".
/// 6. Results summary screen with score, best score persistence, "Play again",
///    and "Back to hub".
/// 7. Questions shuffled per run (configurable for deterministic testing).
class MythBusterScreen extends StatefulWidget {
  const MythBusterScreen({
    super.key,
    this.repository = const BundledRepository(),
    this.shuffleQuestions = true,
  });

  final ContentRepository repository;
  final bool shuffleQuestions;

  @override
  State<MythBusterScreen> createState() => _MythBusterScreenState();
}

class _MythBusterScreenState extends State<MythBusterScreen> {
  late List<MythQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool? _selectedIsMyth;
  bool _quizComplete = false;
  int _bestScore = 0;
  List<QuizScoreRecord> _scoreHistory = [];

  @override
  void initState() {
    super.initState();
    _loadScoreData();
    _startQuiz();
  }

  void _loadScoreData() {
    try {
      final box = Hive.box<dynamic>('settings');
      _bestScore = box.get('quiz_best_score', defaultValue: 0) as int;
      final rawList = box.get('quiz_score_history', defaultValue: <dynamic>[]);
      final list = <QuizScoreRecord>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            list.add(QuizScoreRecord.fromMap(item));
          }
        }
      }
      if (list.isEmpty && _bestScore > 0) {
        list.add(QuizScoreRecord(
          score: _bestScore,
          total: 5,
          date: DateTime.now(),
        ));
      }
      _scoreHistory = list;
    } catch (_) {
      _bestScore = 0;
      _scoreHistory = [];
    }
  }

  Future<void> _recordScore(int score, int total) async {
    try {
      final box = Hive.box<dynamic>('settings');
      final currentBest = box.get('quiz_best_score', defaultValue: 0) as int;
      final newBest = score > currentBest ? score : currentBest;
      if (score > currentBest) {
        await box.put('quiz_best_score', score);
      }

      final rawList = box.get('quiz_score_history', defaultValue: <dynamic>[]);
      final history = <Map<String, dynamic>>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            history.add(Map<String, dynamic>.from(item));
          }
        }
      }

      history.insert(0, {
        'score': score,
        'total': total,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await box.put('quiz_score_history', history);

      if (mounted) {
        setState(() {
          _bestScore = newBest;
          _scoreHistory =
              history.map((e) => QuizScoreRecord.fromMap(e)).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (score > _bestScore) _bestScore = score;
        });
      }
    }
  }

  void _startQuiz() {
    final list = List<MythQuestion>.from(widget.repository.mythQuestions());
    if (widget.shuffleQuestions) {
      list.shuffle();
    }
    setState(() {
      _questions = list;
      _currentIndex = 0;
      _score = 0;
      _selectedIsMyth = null;
      _quizComplete = false;
    });
  }

  void _answerQuestion(bool isMyth) {
    if (_selectedIsMyth != null || _quizComplete) return;

    final question = _questions[_currentIndex];
    final isCorrect = (isMyth == question.isMyth);

    setState(() {
      _selectedIsMyth = isMyth;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedIsMyth = null;
      });
    } else {
      final total = _questions.length;
      if (_score > _bestScore) {
        _bestScore = _score;
      }
      _recordScore(_score, total);
      setState(() {
        _quizComplete = true;
      });
    }
  }

  void _handleHide(BuildContext context) {
    AppToast.dismiss();
    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      context.read<SessionState>().lock();
    } catch (_) {}
    AppRoutes.resetTo(context, const MainScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      _startQuiz();
    }
    final total = _questions.isNotEmpty ? _questions.length : 5;

    return LangBuilder(
      builder: (context, lang) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppTopBar(
            title: t('quiz_title', lang: lang),
            dark: false,
            trailing: HideButton(
              onHide: () => _handleHide(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopScoreBar(context, lang, total),
                Expanded(
                  child: _quizComplete
                      ? _buildResultsView(context, lang)
                      : _buildQuizView(context, lang),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top High Score & Recent Scores Bar ──────────────────────────────

  Widget _buildTopScoreBar(BuildContext context, Lang lang, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppTheme.cardColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Golden Trophy badge
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            // High score text label + value
            Expanded(
              child: InkWell(
                onTap: () => _showScoreHistorySheet(context, lang, total),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('quiz_high_score', lang: lang).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$_bestScore / $total',
                      key: const Key('high_score_display'),
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Icon button for last 5 high scores
            Tooltip(
              message: t('last_5_scores', lang: lang),
              child: Material(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('last_5_scores_button'),
                  onTap: () => _showScoreHistorySheet(context, lang, total),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.leaderboard_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          t('last_5_button', lang: lang),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Last 5 High Scores Modal Bottom Sheet ───────────────────────────

  void _showScoreHistorySheet(BuildContext context, Lang lang, int total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        int activeTab = 0; // 0: Top 5, 1: Recent Attempts
        return StatefulBuilder(
          builder: (context, setModalState) {
            final top5 = List<QuizScoreRecord>.from(_scoreHistory)
              ..sort((a, b) {
                final cmp = b.score.compareTo(a.score);
                if (cmp != 0) return cmp;
                return b.date.compareTo(a.date);
              });
            final topList = top5.take(5).toList();
            final recentList = _scoreHistory.take(5).toList();
            final displayList = activeTab == 0 ? topList : recentList;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('last_5_scores', lang: lang),
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${t('quiz_high_score', lang: lang)}: $_bestScore / $total',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.textDark),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                    ),

                    // Tab selector
                    if (_scoreHistory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => activeTab = 0),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: activeTab == 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: activeTab == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t('top_5_scores', lang: lang),
                                        style: TextStyle(
                                          color: activeTab == 0
                                              ? AppTheme.primaryDark
                                              : AppTheme.textLight,
                                          fontSize: 12.5,
                                          fontWeight: activeTab == 0
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => activeTab = 1),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: activeTab == 1
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: activeTab == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        t('recent_attempts', lang: lang),
                                        style: TextStyle(
                                          color: activeTab == 1
                                              ? AppTheme.primaryDark
                                              : AppTheme.textLight,
                                          fontSize: 12.5,
                                          fontWeight: activeTab == 1
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Scores List or Empty View
                    Flexible(
                      child: _scoreHistory.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 36,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.cardColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.military_tech_outlined,
                                      color: AppTheme.primaryColor,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    t('no_scores_recorded', lang: lang),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppTheme.textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t('play_quiz_to_record', lang: lang),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              itemCount: displayList.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final record = displayList[index];
                                final rank = index + 1;
                                final isFirst = rank == 1 && activeTab == 0;
                                final isSecond = rank == 2 && activeTab == 0;
                                final isThird = rank == 3 && activeTab == 0;

                                final rankBg = isFirst
                                    ? const Color(0xFFFEF3C7)
                                    : isSecond
                                        ? const Color(0xFFF1F5F9)
                                        : isThird
                                            ? const Color(0xFFFFEDD5)
                                            : AppTheme.cardColor;

                                final rankColor = isFirst
                                    ? const Color(0xFFB45309)
                                    : isSecond
                                        ? const Color(0xFF475569)
                                        : isThird
                                            ? const Color(0xFFC2410C)
                                            : AppTheme.textDark;

                                final percentage =
                                    ((record.score / record.total) * 100)
                                        .round();
                                final dateStr = DateFormat('d MMM, h:mm a')
                                    .format(record.date);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? const Color(0xFFFFFBEB)
                                        : const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isFirst
                                          ? const Color(0xFFFDE68A)
                                          : Colors.grey.shade200,
                                      width: isFirst ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank Badge
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: rankBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: isFirst
                                              ? const Icon(
                                                  Icons.emoji_events_rounded,
                                                  color: Color(0xFFD97706),
                                                  size: 18,
                                                )
                                              : Text(
                                                  '#$rank',
                                                  style: TextStyle(
                                                    color: rankColor,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Score & Date
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${record.score} / ${record.total}',
                                                  style: const TextStyle(
                                                    color: AppTheme.textDark,
                                                    fontSize: 16.5,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: percentage == 100
                                                        ? const Color(0xFFDCFCE7)
                                                        : AppTheme.cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '$percentage%',
                                                    style: TextStyle(
                                                      color: percentage == 100
                                                          ? const Color(0xFF15803D)
                                                          : AppTheme.primaryDark,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                color: AppTheme.textLight,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
          },
        );
      },
    );
  }

  // ── Quiz Active View ───────────────────────────────────────────────

  Widget _buildQuizView(BuildContext context, Lang lang) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available',
          style: TextStyle(color: AppTheme.textLight),
        ),
      );
    }

    final total = _questions.length;
    final currentNumber = _currentIndex + 1;
    final question = _questions[_currentIndex];
    final progressValue = currentNumber / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Progress Header ────────────────────────────────────────
          Text(
            t('quiz_progress', lang: lang, params: {
              'n': '$currentNumber',
              'total': '$total',
            }),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: progressValue,
            color: AppTheme.primaryColor,
            trackColor: AppTheme.cardColor,
            height: 8,
          ),
          const SizedBox(height: 20),

          // ── White Question Card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Question badge icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE8EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Color(0xFFB01848),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Statement in quotes
                Text(
                  '“${question.statement.of(lang)}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Sub-prompt
                Text(
                  t('quiz_prompt', lang: lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Response State: Buttons or Feedback ──────────────
                if (_selectedIsMyth == null)
                  Column(
                    children: [
                      // 1. "It's a MYTH" filled pink button
                      Material(
                        color: AppTheme.primaryColor,
                        shape: const StadiumBorder(),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _answerQuestion(true),
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: Text(
                                t('its_myth', lang: lang),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. "It's a FACT" outlined primary pink button
                      Material(
                        color: Colors.white,
                        shape: const StadiumBorder(
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _answerQuestion(false),
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: Text(
                                t('its_fact', lang: lang),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      // ── Feedback Banner ────────────────────────────────
                      _buildFeedbackBanner(context, question, lang),
                      const SizedBox(height: 20),

                      // ── Next / See Results Button ──────────────────────
                      Material(
                        color: AppTheme.primaryColor,
                        shape: const StadiumBorder(),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _nextQuestion,
                          child: SizedBox(
                            height: 52,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentNumber == total
                                      ? (lang == Lang.si
                                          ? 'ප්‍රතිඵල බලන්න'
                                          : 'See Results')
                                      : t('next', lang: lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Feedback Banner ────────────────────────────────────────────────

  Widget _buildFeedbackBanner(
    BuildContext context,
    MythQuestion question,
    Lang lang,
  ) {
    final wasCorrect = (_selectedIsMyth == question.isMyth);
    final isMythAnswer = question.isMyth;

    final bgColor = wasCorrect
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFF1F2);
    final borderColor = wasCorrect
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFFECDD3);
    final accentColor = wasCorrect
        ? const Color(0xFF16A34A)
        : const Color(0xFFE11D48);

    final headline = wasCorrect
        ? t('quiz_correct', lang: lang)
        : t('quiz_incorrect', lang: lang);

    final truthLabel = isMythAnswer
        ? t('its_myth', lang: lang)
        : t('its_fact', lang: lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '$headline ($truthLabel)',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation.of(lang),
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ── Results View ───────────────────────────────────────────────────

  Widget _buildResultsView(BuildContext context, Lang lang) {
    final total = _questions.length;
    final isPerfect = (_score == total);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy / celebration badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isPerfect
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFFDE8EF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isPerfect
                        ? Icons.emoji_events_rounded
                        : Icons.psychology_rounded,
                    color: isPerfect
                        ? const Color(0xFFD97706)
                        : const Color(0xFFB01848),
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                lang == Lang.si ? 'ප්‍රශ්නාවලිය අවසන්!' : 'Quiz Complete!',
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),

              // Score text
              Text(
                t('quiz_result', lang: lang, params: {
                  'score': '$_score',
                  'total': '$total',
                }),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),

              // Best score
              Text(
                lang == Lang.si
                    ? 'හොඳම ලකුණු: $_bestScore / $total'
                    : 'Personal Best: $_bestScore / $total',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              // "Play again" primary button
              Material(
                color: AppTheme.primaryColor,
                shape: const StadiumBorder(),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _startQuiz,
                  child: SizedBox(
                    height: 52,
                    child: Center(
                      child: Text(
                        t('play_again', lang: lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // "Back to hub" secondary button
              Material(
                color: Colors.white,
                shape: const StadiumBorder(
                  side: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      AppRoutes.resetTo(context, const MainScreen());
                    }
                  },
                  child: SizedBox(
                    height: 52,
                    child: Center(
                      child: Text(
                        t('back_to_hub', lang: lang),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
