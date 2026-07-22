import 'package:equatable/equatable.dart';

enum PuzzleDifficulty { easy, medium, hard }

class WordPuzzle extends Equatable {

  factory WordPuzzle.generate(String id, String answer, String hint) {
    final letters = answer.toUpperCase().split('')..shuffle();
    // Make sure it's actually scrambled (not same as answer)
    var scrambled = letters.join();
    if (scrambled == answer.toUpperCase() && answer.length > 1) {
      scrambled = answer.toUpperCase().split('').reversed.join();
    }
    return WordPuzzle(
      id: id,
      answer: answer.toUpperCase(),
      hint: hint,
      scrambled: scrambled,
      difficulty: _difficultyFor(answer.length),
      points: _pointsFor(answer.length),
    );
  }
  const WordPuzzle({
    required this.id,
    required this.answer,
    required this.hint,
    required this.scrambled,
    required this.difficulty,
    required this.points,
  });

  final String id;
  final String answer;
  final String hint;
  final String scrambled;
  final PuzzleDifficulty difficulty;
  final int points;

  static PuzzleDifficulty _difficultyFor(int length) {
    if (length <= 4) return PuzzleDifficulty.easy;
    if (length <= 6) return PuzzleDifficulty.medium;
    return PuzzleDifficulty.hard;
  }

  static int _pointsFor(int length) {
    if (length <= 4) return 10;
    if (length <= 6) return 20;
    return 30;
  }

  @override
  List<Object?> get props => [id, answer, hint, scrambled, difficulty, points];
}
