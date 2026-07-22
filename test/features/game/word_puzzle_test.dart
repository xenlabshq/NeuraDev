import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/game/domain/entities/word_puzzle.dart';

void main() {
  group('WordPuzzle.generate', () {
    test('produces scrambled different from answer for multi-char', () {
      final p = WordPuzzle.generate('p1', 'KEDİ', 'mIYAV');
      expect(p.answer, 'KEDİ');
      expect(p.scrambled.length, p.answer.length);
      expect(p.scrambled, isNot(equals(p.answer)));
    });

    test('handles single character (no scramble possible)', () {
      final p = WordPuzzle.generate('p2', 'A', 'letter');
      expect(p.scrambled, 'A');
    });

    test('assigns difficulty by length', () {
      final easy = WordPuzzle.generate('e', 'KEDİ', 'h');
      final med = WordPuzzle.generate('m', 'BULUT', 'h');
      final hard = WordPuzzle.generate('h', 'ASTRONOT', 'h');
      expect(easy.difficulty, PuzzleDifficulty.easy);
      expect(med.difficulty, PuzzleDifficulty.medium);
      expect(hard.difficulty, PuzzleDifficulty.hard);
    });

    test('points scale with length', () {
      final easy = WordPuzzle.generate('e', 'KEDİ', 'h');
      final med = WordPuzzle.generate('m', 'BULUT', 'h');
      final hard = WordPuzzle.generate('h', 'ASTRONOT', 'h');
      expect(easy.points, lessThan(med.points));
      expect(med.points, lessThan(hard.points));
    });
  });
}
