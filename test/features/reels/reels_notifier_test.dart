import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reels/data/in_memory_reels_repository.dart';
import 'package:neuroup/features/reels/domain/entities/game_reel.dart';
import 'package:neuroup/features/reels/presentation/providers/reels_providers.dart';

// `uploaderId` gerçek bir gönderimde her zaman dolu olur (bkz.
// ReelSubmitPage._submit) — `mergeSubmitted` seed reels'i (uploaderId ==
// null) submission'lardan bu alana bakarak ayırt ediyor, bu yüzden test
// fikstürü de gerçekçi olmalı.
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
  uploaderId: 'submitter_$id',
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

  test(
    'mergeSubmitted drops a submission that disappeared from the stream '
    '(deleted)',
    () {
      final notifier = ReelsNotifier(InMemoryReelsRepository());
      final seedCount = notifier.state.length;
      notifier.mergeSubmitted([_submitted('user_1'), _submitted('user_2')]);
      expect(notifier.state.length, seedCount + 2);

      // Silinmiş gibi — akışta artık sadece 'user_2' var.
      notifier.mergeSubmitted([_submitted('user_2')]);

      expect(notifier.state.length, seedCount + 1);
      expect(notifier.state.any((r) => r.id == 'user_1'), isFalse);
    },
  );

  test('removeReel deletes the reel immediately without waiting for a '
      'stream round-trip', () {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    notifier.mergeSubmitted([_submitted('user_1')]);
    expect(notifier.state.any((r) => r.id == 'user_1'), isTrue);

    notifier.removeReel('user_1');

    expect(notifier.state.any((r) => r.id == 'user_1'), isFalse);
  });

  test(
    'mergeSubmitted updates edited content but preserves local '
    'like/save/comment state',
    () {
      final notifier = ReelsNotifier(InMemoryReelsRepository());
      notifier.mergeSubmitted([_submitted('user_1')]);
      notifier.toggleLike('user_1');
      notifier.toggleSave('user_1');
      notifier.addComment('user_1', 'ilk yorum');
      final beforeEdit = notifier.state.firstWhere((r) => r.id == 'user_1');
      expect(beforeEdit.liked, isTrue);
      expect(beforeEdit.saved, isTrue);
      expect(beforeEdit.comments, hasLength(1));

      final edited = GameReel(
        id: 'user_1',
        devName: 'Test Dev',
        devTag: '@testdev',
        title: 'Güncellenmiş Başlık',
        caption: 'caption',
        tags: '#test',
        accent: ReelAccent.gold,
        symbols: const ['🎮'],
        hud: 'Yeni',
        likes: 0,
        gameUrl: 'https://example.com/game',
        uploaderId: 'submitter_user_1',
        comments: const [],
      );
      notifier.mergeSubmitted([edited]);

      final afterEdit = notifier.state.firstWhere((r) => r.id == 'user_1');
      expect(afterEdit.title, 'Güncellenmiş Başlık');
      expect(afterEdit.liked, isTrue);
      expect(afterEdit.saved, isTrue);
      expect(afterEdit.comments, hasLength(1));
    },
  );

  test(
    'mergeSubmitted hides a submission whose expiresAt has passed',
    () {
      final notifier = ReelsNotifier(InMemoryReelsRepository());
      final seedCount = notifier.state.length;
      final expired = GameReel(
        id: 'user_1',
        devName: 'Test Dev',
        devTag: '@testdev',
        title: 'Süresi Dolmuş',
        caption: 'caption',
        tags: '#test',
        accent: ReelAccent.gold,
        symbols: const ['🎮'],
        hud: 'Yeni',
        likes: 0,
        gameUrl: 'https://example.com/game',
        uploaderId: 'submitter_user_1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        comments: const [],
      );

      notifier.mergeSubmitted([expired]);

      expect(notifier.state.length, seedCount);
      expect(notifier.state.any((r) => r.id == 'user_1'), isFalse);
    },
  );

  test(
    'mergeSubmitted keeps a submission whose expiresAt is still in the '
    'future',
    () {
      final notifier = ReelsNotifier(InMemoryReelsRepository());
      final seedCount = notifier.state.length;
      final fresh = GameReel(
        id: 'user_1',
        devName: 'Test Dev',
        devTag: '@testdev',
        title: 'Taze',
        caption: 'caption',
        tags: '#test',
        accent: ReelAccent.gold,
        symbols: const ['🎮'],
        hud: 'Yeni',
        likes: 0,
        gameUrl: 'https://example.com/game',
        uploaderId: 'submitter_user_1',
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
        comments: const [],
      );

      notifier.mergeSubmitted([fresh]);

      expect(notifier.state.length, seedCount + 1);
      expect(notifier.state.any((r) => r.id == 'user_1'), isTrue);
    },
  );

  test('loadMore has nothing left after the seed is exhausted', () async {
    final notifier = ReelsNotifier(InMemoryReelsRepository());
    final seedCount = notifier.state.length;
    expect(notifier.hasMore, isTrue);

    await notifier.loadMore();

    expect(notifier.state.length, seedCount);
    expect(notifier.hasMore, isFalse);
  });
}
