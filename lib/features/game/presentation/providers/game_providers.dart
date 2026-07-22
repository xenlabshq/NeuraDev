import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/game/data/repositories/game_repository_impl.dart';
import 'package:neuroup/features/game/domain/entities/word_puzzle.dart';
import 'package:neuroup/features/game/domain/repositories/game_repository.dart';

final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepositoryImpl(ref.watch(firestoreProvider)),
);

final puzzlesProvider = FutureProvider<List<WordPuzzle>>((ref) async {
  await ref.read(gameRepositoryProvider).seedIfEmpty();
  return ref.read(gameRepositoryProvider).getPuzzles();
});
