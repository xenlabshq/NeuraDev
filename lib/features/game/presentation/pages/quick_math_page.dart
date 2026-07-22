import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:neuroup/app/theme/colors.dart';

class QuickMathPage extends ConsumerStatefulWidget {
  const QuickMathPage({super.key});

  @override
  ConsumerState<QuickMathPage> createState() => _QuickMathPageState();
}

class _QuickMathPageState extends ConsumerState<QuickMathPage> {
  static const int _duration = 60;
  int _score = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  int _timeLeft = _duration;
  int _streak = 0;
  Timer? _timer;
  int _a = 0;
  int _b = 0;
  int _op = 0; // 0=+, 1=-, 2=*, 3=/
  int? _selectedAnswer;
  bool _showFeedback = false;
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        _showResults();
      }
    });
  }

  void _newQuestion() {
    final rand = math.Random();
    _op = rand.nextInt(3); // +, -, *
    switch (_op) {
      case 0: // toplama
        _a = rand.nextInt(50) + 1;
        _b = rand.nextInt(50) + 1;
      case 1: // çıkarma
        _a = rand.nextInt(50) + 20;
        _b = rand.nextInt(_a);
      case 2: // çarpma
        _a = rand.nextInt(12) + 1;
        _b = rand.nextInt(12) + 1;
    }
    final correct = _calculate(_a, _b, _op);
    _options = _generateOptions(correct);
    _selectedAnswer = null;
    _showFeedback = false;
  }

  int _calculate(int a, int b, int op) {
    switch (op) {
      case 0:
        return a + b;
      case 1:
        return a - b;
      case 2:
        return a * b;
    }
    return 0;
  }

  List<int> _generateOptions(int correct) {
    final rand = math.Random();
    final opts = <int>{correct};
    while (opts.length < 4) {
      final delta = rand.nextInt(15) + 1;
      final sign = rand.nextBool() ? 1 : -1;
      opts.add(correct + sign * delta);
    }
    return opts.toList()..shuffle();
  }

  void _selectAnswer(int answer) {
    if (_showFeedback) return;
    final correct = _calculate(_a, _b, _op);
    final isCorrect = answer == correct;
    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
      _questionsAnswered++;
      if (isCorrect) {
        _correctAnswers++;
        _score += 10 + (_streak * 2);
        _streak++;
      } else {
        _streak = 0;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _newQuestion();
      setState(() {});
    });
  }

  void _showResults() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Süre Doldu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score > 200 ? Icons.emoji_events : Icons.star,
              color: AppColors.gold,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '$_score puan',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_correctAnswers / $_questionsAnswered doğru',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Çıkış'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _score = 0;
                _questionsAnswered = 0;
                _correctAnswers = 0;
                _streak = 0;
                _timeLeft = _duration;
                _newQuestion();
                _startTimer();
              });
            },
            child: const Text('Tekrar'),
          ),
        ],
      ),
    );
  }

  String _opSymbol(int op) => switch (op) {
        0 => '+',
        1 => '−',
        2 => '×',
        _ => '?',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              score: _score,
              timeLeft: _timeLeft,
              streak: _streak,
              questionsAnswered: _questionsAnswered,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_a ${_opSymbol(_op)} $_b = ?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: MediaQuery.sizeOf(context).width < 380
                            ? 1.2
                            : (MediaQuery.sizeOf(context).width < 600
                                ? 1.5
                                : 1.8),
                        physics: const NeverScrollableScrollPhysics(),
                        children: _options.map((opt) {
                          return _MathOption(
                            value: opt,
                            selected: _selectedAnswer == opt,
                            correct: _calculate(_a, _b, _op),
                            showFeedback: _showFeedback,
                            onTap: () => _selectAnswer(opt),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.timeLeft,
    required this.streak,
    required this.questionsAnswered,
  });
  final int score;
  final int timeLeft;
  final int streak;
  final int questionsAnswered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${timeLeft}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (streak > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'x$streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Text(
                '$questionsAnswered soru',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MathOption extends StatelessWidget {
  const _MathOption({
    required this.value,
    required this.selected,
    required this.correct,
    required this.showFeedback,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final int correct;
  final bool showFeedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var bg = Colors.white.withValues(alpha: 0.1);
    var border = Colors.white.withValues(alpha: 0.2);
    var text = Colors.white;
    IconData? icon;

    if (showFeedback) {
      if (value == correct) {
        bg = AppColors.success.withValues(alpha: 0.2);
        border = AppColors.success;
        icon = Icons.check_rounded;
      } else if (selected) {
        bg = AppColors.error.withValues(alpha: 0.2);
        border = AppColors.error;
        icon = Icons.close_rounded;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: text, size: 20),
                const SizedBox(width: 6),
              ],
              Text(
                '$value',
                style: TextStyle(
                  color: text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
