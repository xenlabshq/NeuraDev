import '../domain/entities/game_reel.dart';
import '../domain/repositories/reels_repository.dart';
import 'reels_seed.dart';

class InMemoryReelsRepository implements ReelsRepository {
  InMemoryReelsRepository() : _reels = List.of(ReelsSeed.all());

  final List<GameReel> _reels;

  @override
  List<GameReel> getAll() => List.unmodifiable(_reels);

  @override
  GameReel? getById(String id) {
    for (final r in _reels) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  GameReel toggleLike(String id) {
    final i = _reels.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Reel not found: $id');
    final r = _reels[i];
    final liked = !r.liked;
    _reels[i] = r.copyWith(
      liked: liked,
      likes: r.likes + (liked ? 1 : -1),
    );
    return _reels[i];
  }

  @override
  GameReel toggleSave(String id) {
    final i = _reels.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Reel not found: $id');
    final r = _reels[i];
    _reels[i] = r.copyWith(saved: !r.saved);
    return _reels[i];
  }

  @override
  GameReel toggleFollow(String id) {
    final i = _reels.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Reel not found: $id');
    final r = _reels[i];
    _reels[i] = r.copyWith(following: !r.following);
    return _reels[i];
  }

  @override
  GameReel addComment(String reelId, String text) {
    final i = _reels.indexWhere((r) => r.id == reelId);
    if (i < 0) throw StateError('Reel not found: $reelId');
    final r = _reels[i];
    final newComment = ReelComment(user: '@sen', text: text, isMe: true);
    final updated = [newComment, ...r.comments];
    _reels[i] = r.copyWith(comments: updated);
    return _reels[i];
  }
}