import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reels/data/in_memory_reels_repository.dart';
import 'package:neuroup/features/reels/domain/entities/game_reel.dart';
import 'package:neuroup/features/reels/presentation/providers/reels_providers.dart';

GameReel _submitted(String id) => GameReel(
  id: id,
  devName: 'Test Dev',
  devTag: '@testdev',
  title: 'Gönderilen Oyun',
  caption: 'caption',
  tags: '#test',
  accent: ReelAccent.gold,
  symbols: const ['🎮'],
  hud: 'Yeni',
  likes: 0,
  gameUrl: 'https://example.com/game',
  comments: const [],
);

void main() {
  test('initial state comes from the seed repository', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    expect(notifier.state.length, 5);
  });

  test('toggleLike flips liked and adjusts the like count locally', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    final before = notifier.state.first;

    notifier.toggleLike(before.id);

    final after = notifier.state.first;
    expect(after.liked, !before.liked);
    expect(after.likes, before.likes + (after.liked ? 1 : -1));
  });

  test('mergeSubmitted prepends new reels not already in state', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    final seedCount = notifier.state.length;

    notifier.mergeSubmitted([_submitted('user_1')]);

    expect(notifier.state.length, seedCount + 1);
    expect(notifier.state.first.id, 'user_1');
  });

  test('mergeSubmitted does not duplicate an already-merged reel', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    notifier.mergeSubmitted([_submitted('user_1')]);
    final afterFirstMerge = notifier.state.length;

    notifier.mergeSubmitted([_submitted('user_1')]);

    expect(notifier.state.length, afterFirstMerge);
  });

  test('addComment works on a merged (non-seed) reel', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    notifier.mergeSubmitted([_submitted('user_1')]);

    notifier.addComment('user_1', 'harika fikir!');

    final reel = notifier.state.firstWhere((r) => r.id == 'user_1');
    expect(reel.comments.first.text, 'harika fikir!');
  });
}
