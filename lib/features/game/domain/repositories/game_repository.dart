import 'package:neuroup/features/game/domain/entities/game_score.dart';
import 'package:neuroup/features/game/domain/entities/word_puzzle.dart';

abstract class GameRepository {
  Future<List<WordPuzzle>> getPuzzles();
  Future<void> seedIfEmpty();
  Future<void> saveScore(GameScore score);
  Future<List<GameScore>> getTopScores(String gameId, {int limit = 10});
}
