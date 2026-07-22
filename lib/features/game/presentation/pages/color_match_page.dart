import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:neuroup/app/theme/colors.dart';

/// Simon Says tarzı renk ezberleme oyunu.
/// Kullanıcı ekranda yanıp sönen renk dizisini tekrar etmeli.
class ColorMatchPage extends ConsumerStatefulWidget {
  const ColorMatchPage({super.key});

  @override
  ConsumerState<ColorMatchPage> createState() => _ColorMatchPageState();
}

class _ColorMatchPageState extends ConsumerState<ColorMatchPage> {
  static const List<Color> _colors = [
    Color(0xFFEF4444), // red
    Color(0xFF10B981), // green
    Color(0xFFFBBF24), // yellow
    Color(0xFF3B82F6), // blue
  ];

  int _score = 0;
  int _bestStreak = 0;
  int _currentStreak = 0;
  int _level = 1;
  List<int> _sequence = [];
  int _userIndex = 0;
  int? _highlightedIndex;
  bool _showingSequence = false;
  bool _acceptingInput = false;
  String _status = 'Başlamak için butona dokun';
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _level = 1;
      _currentStreak = 0;
      _sequence = [];
      _score = 0;
      _userIndex = 0;
      _acceptingInput = false;
      _status = 'Hazır ol!';
    });
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _userIndex = 0;
      _sequence.add(math.Random().nextInt(4));
      _showingSequence = true;
      _acceptingInput = false;
    });
    _playSequence();
  }

  void _playSequence() {
    var i = 0;
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i >= _sequence.length) {
        timer.cancel();
        setState(() {
          _showingSequence = false;
          _acceptingInput = true;
          _highlightedIndex = null;
          _status = 'Sırayı tekrar et';
        });
        return;
      }
      setState(() => _highlightedIndex = _sequence[i]);
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _highlightedIndex = null);
        }
      });
      i++;
    });
  }

  void _onColorTap(int index) {
    if (!_acceptingInput) return;
    setState(() => _highlightedIndex = index);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _highlightedIndex = null);
    });

    if (index == _sequence[_userIndex]) {
      _userIndex++;
      if (_userIndex >= _sequence.length) {
        // Tur başarılı
        final bonus = _level * 10;
        setState(() {
          _score += bonus;
          _currentStreak++;
          if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
          _level++;
          _status = '✓ Doğru! +$bonus puan';
          _acceptingInput = false;
        });
        Future<void>.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _nextRound();
        });
      }
    } else {
      // Hata
      setState(() {
        _status = '✗ Yanlış! Oyun bitti';
        _currentStreak = 0;
        _acceptingInput = false;
        _showingSequence = true; // durdur
      });
      _t?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showingSequence = false;
            _highlightedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              score: _score,
              level: _level,
              streak: _currentStreak,
              bestStreak: _bestStreak,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: List.generate(4, (i) {
                      final highlighted = _highlightedIndex == i;
                      return _ColorTile(
                        color: _colors[i],
                        highlighted: highlighted,
                        disabled: !_acceptingInput && !_showingSequence,
                        onTap: () => _onColorTap(i),
                      );
                    }),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _sequence.isEmpty
                        ? AppColors.success
                        : AppColors.primary,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: Icon(
                    _sequence.isEmpty
                        ? Icons.play_arrow_rounded
                        : Icons.replay_rounded,
                    size: 22,
                  ),
                  label: Text(
                    _sequence.isEmpty ? 'Başla' : 'Yeniden Başla',
                  ),
                  onPressed: _start,
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
    required this.level,
    required this.streak,
    required this.bestStreak,
  });
  final int score;
  final int level;
  final int streak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          _Stat(label: 'Seviye', value: '$level', color: AppColors.accent),
          const SizedBox(width: 16),
          _Stat(
            label: 'Seri',
            value: '$streak',
            color: AppColors.warning,
          ),
          const Spacer(),
          _Stat(label: 'En İyi', value: '$bestStreak', color: AppColors.gold),
          const SizedBox(width: 16),
          _Stat(label: 'Puan', value: '$score', color: AppColors.success),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.color,
    required this.highlighted,
    required this.disabled,
    required this.onTap,
  });
  final Color color;
  final bool highlighted;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: highlighted
            ? color
            : color.withValues(alpha: disabled ? 0.25 : 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? Colors.white : Colors.transparent,
          width: 4,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled ? null : onTap,
        ),
      ),
    );
  }
}
