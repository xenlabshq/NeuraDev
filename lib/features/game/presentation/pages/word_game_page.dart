import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart' show currentAuthUserProvider;
import 'package:neuroup/features/game/domain/entities/game_score.dart';
import 'package:neuroup/features/game/domain/entities/word_puzzle.dart';
import 'package:neuroup/features/game/presentation/providers/game_providers.dart';

class WordGamePage extends ConsumerStatefulWidget {
  const WordGamePage({super.key});
  @override
  ConsumerState<WordGamePage> createState() => _WordGamePageState();
}

class _WordGamePageState extends ConsumerState<WordGamePage> {
  int _index = 0;
  String _current = '';
  int _score = 0;
  int _streak = 0;
  String? _feedback;
  bool _won = false;
  DateTime _start = DateTime.now();

  void _onTap(String letter) {
    if (_won) return;
    setState(() {
      _current += letter;
      _feedback = null;
    });
  }

  void _undo() {
    if (_current.isEmpty || _won) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _clear() {
    if (_won) return;
    setState(() => _current = '');
  }

  void _check(WordPuzzle puzzle) {
    if (_current.length != puzzle.answer.length) {
      setState(() => _feedback = '⚠️ Eksik harf var');
      return;
    }
    if (_current == puzzle.answer) {
      final bonus = _streak * 5;
      setState(() {
        _score += puzzle.points + bonus;
        _streak += 1;
        _feedback = '✓ Doğru! +${puzzle.points + bonus} puan';
        _won = true;
      });
    } else {
      setState(() {
        _streak = 0;
        _feedback = '✗ Yanlış, tekrar dene';
      });
    }
  }

  Future<void> _next(List<WordPuzzle> puzzles) async {
    if (_index < puzzles.length - 1) {
      setState(() {
        _index += 1;
        _current = '';
        _feedback = null;
        _won = false;
        _start = DateTime.now();
      });
    } else {
      await _saveFinalScore();
      if (!mounted) return;
      setState(() {
        _feedback = '🎉 Tüm bulmacalar bitti! Toplam $_score puan';
        _won = true;
      });
    }
  }

  Future<void> _saveFinalScore() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    final score = GameScore(
      userId: user.id,
      gameId: 'word_hunt',
      score: _score,
      completedAt: DateTime.now(),
      durationSeconds: DateTime.now().difference(_start).inSeconds,
    );
    await ref.read(gameRepositoryProvider).saveScore(score);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPuzzles = ref.watch(puzzlesProvider);
    return Scaffold(
      body: asyncPuzzles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (puzzles) {
          if (puzzles.isEmpty) {
            return const Center(child: Text('Bulmaca yok'));
          }
          final puzzle = puzzles[_index];
          return _GameView(
            puzzle: puzzle,
            current: _current,
            feedback: _feedback,
            streak: _streak,
            score: _score,
            index: _index,
            total: puzzles.length,
            won: _won,
            onTap: _onTap,
            onUndo: _undo,
            onClear: _clear,
            onCheck: () => _check(puzzle),
            onNext: () => _next(puzzles),
            onSkip: () => _next(puzzles),
          );
        },
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({
    required this.puzzle,
    required this.current,
    required this.feedback,
    required this.streak,
    required this.score,
    required this.index,
    required this.total,
    required this.won,
    required this.onTap,
    required this.onUndo,
    required this.onClear,
    required this.onCheck,
    required this.onNext,
    required this.onSkip,
  });

  final WordPuzzle puzzle;
  final String current;
  final String? feedback;
  final int streak;
  final int score;
  final int index;
  final int total;
  final bool won;
  final void Function(String letter) onTap;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onCheck;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  int _countOf(String s, String ch) =>
      s.split('').where((c) => c == ch).length;

  @override
  Widget build(BuildContext context) {
    final slots = List<String>.generate(
      puzzle.answer.length,
      (i) => i < current.length ? current[i] : '',
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Kelime Avı',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Bulmaca ${index + 1} / $total',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (streak > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'x$streak',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (index + 1) / total,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      puzzle.hint,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 48,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: slots[i].isEmpty
                            ? Colors.white
                            : AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: slots[i].isEmpty
                              ? AppColors.border
                              : AppColors.primary,
                          width: 1.5,
                        ),
                        boxShadow: slots[i].isEmpty
                            ? null
                            : [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Text(
                        slots[i],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: slots[i].isEmpty
                              ? AppColors.textTertiary
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (feedback != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: feedback!.startsWith('✓') || feedback!.startsWith('🎉')
                      ? AppColors.success.withValues(alpha: 0.12)
                      : feedback!.startsWith('✗') || feedback!.startsWith('⚠')
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: feedback!.startsWith('✓') || feedback!.startsWith('🎉')
                        ? AppColors.success.withValues(alpha: 0.3)
                        : feedback!.startsWith('✗') || feedback!.startsWith('⚠')
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.border,
                  ),
                ),
                child: Text(
                  feedback!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Harfler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < puzzle.scrambled.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: _LetterButton(
                      letter: puzzle.scrambled[i],
                      used: current.contains(puzzle.scrambled[i]) &&
                          _countOf(current, puzzle.scrambled[i]) >=
                              _countOf(puzzle.scrambled, puzzle.scrambled[i]) -
                                  puzzle.scrambled
                                      .substring(i + 1)
                                      .split(puzzle.scrambled[i])
                                      .length +
                                  1,
                      onTap: () => onTap(puzzle.scrambled[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _CircleAction(
                  icon: Icons.undo_rounded,
                  onPressed: won ? null : onUndo,
                ),
                const SizedBox(width: 10),
                _CircleAction(
                  icon: Icons.clear_rounded,
                  onPressed: won ? null : onClear,
                ),
                const Spacer(),
                if (won)
                  FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Sonraki'),
                    onPressed: onNext,
                  )
                else ...[
                  OutlinedButton(
                    onPressed: onSkip,
                    child: const Text('Atla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Kontrol'),
                    onPressed: onCheck,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LetterButton extends StatelessWidget {
  const _LetterButton(
      {required this.letter, required this.used, required this.onTap});
  final String letter;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: used ? null : onTap,
        child: Container(
          width: 48,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: used ? AppColors.surfaceAlt : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: used
                  ? AppColors.border
                  : AppColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: used
                  ? AppColors.textTertiary
                  : AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onPressed == null
                ? AppColors.textTertiary
                : AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
