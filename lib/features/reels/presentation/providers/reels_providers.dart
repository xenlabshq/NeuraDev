import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_reel.dart';
import '../../domain/repositories/reels_repository.dart';
import '../../data/in_memory_reels_repository.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => InMemoryReelsRepository(),
);

final reelsProvider = StateNotifierProvider<ReelsNotifier, List<GameReel>>(
  (ref) => ReelsNotifier(ref.read(reelsRepositoryProvider)),
);

class ReelsNotifier extends StateNotifier<List<GameReel>> {
  ReelsNotifier(this._repo) : super(_repo.getAll());

  final ReelsRepository _repo;

  void toggleLike(String id) {
    _repo.toggleLike(id);
    state = _repo.getAll();
  }

  void toggleSave(String id) {
    _repo.toggleSave(id);
    state = _repo.getAll();
  }

  void toggleFollow(String id) {
    _repo.toggleFollow(id);
    state = _repo.getAll();
  }

  void addComment(String reelId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _repo.addComment(reelId, trimmed);
    state = _repo.getAll();
  }
}

final reelProvider = Provider.family<GameReel?, String>((ref, id) {
  final reels = ref.watch(reelsProvider);
  for (final r in reels) {
    if (r.id == id) return r;
  }
  return null;
});