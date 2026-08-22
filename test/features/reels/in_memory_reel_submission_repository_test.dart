import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reels/data/in_memory_reel_submission_repository.dart';
import 'package:neuroup/features/reels/data/reel_submission_repository_impl.dart'
    show reelUploadCooldown;
import 'package:neuroup/features/reels/domain/entities/game_reel.dart';

GameReel _reel({
  String title = 'Test Oyunu',
  ReelMediaType mediaType = ReelMediaType.video,
}) => GameReel(
  id: '',
  devName: 'Test Dev',
  devTag: '@testdev',
  title: title,
  caption: 'caption',
  tags: '#test',
  accent: ReelAccent.gold,
  symbols: const ['🎮'],
  hud: 'Yeni',
  likes: 0,
  gameUrl: 'https://example.com/game',
  mediaType: mediaType,
  comments: const [],
);

void main() {
  test(
    'watchSubmittedReels yields an empty list before any submission',
    () async {
      final repo = InMemoryReelSubmissionRepository();
      final first = await repo.watchSubmittedReels().first;
      expect(first, isEmpty);
    },
  );

  test('submitReel adds the reel and it appears in the stream', () async {
    final repo = InMemoryReelSubmissionRepository();
    final events = <List<GameReel>>[];
    final sub = repo.watchSubmittedReels().listen(events.add);
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(events.last.length, 1);
    expect(events.last.first.title, 'Test Oyunu');
  });

  test('multiple submissions are prepended (most recent first)', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(_reel(title: 'Birinci'), submittedByUid: 'uid_1');
    await repo.submitReel(_reel(title: 'İkinci'), submittedByUid: 'uid_2');
    final list = await repo.watchSubmittedReels().first;

    expect(list.map((r) => r.title).toList(), ['İkinci', 'Birinci']);
  });

  test('submitReel assigns a real (non-empty) id', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    final saved = (await repo.watchSubmittedReels().first).single;

    expect(saved.id, isNotEmpty);
  });

  test('updateReel changes the title of an existing submission', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(_reel(title: 'Eski'), submittedByUid: 'uid_1');
    final saved = (await repo.watchSubmittedReels().first).single;

    await repo.updateReel(
      GameReel(
        id: saved.id,
        devName: saved.devName,
        devTag: saved.devTag,
        title: 'Yeni',
        caption: saved.caption,
        tags: saved.tags,
        accent: saved.accent,
        symbols: saved.symbols,
        hud: saved.hud,
        likes: saved.likes,
        gameUrl: saved.gameUrl,
        uploaderId: saved.uploaderId,
        comments: saved.comments,
      ),
    );

    final updated = (await repo.watchSubmittedReels().first).single;
    expect(updated.title, 'Yeni');
    expect(updated.id, saved.id);
  });

  test('deleteReel removes the submission from the stream', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    final saved = (await repo.watchSubmittedReels().first).single;

    await repo.deleteReel(saved.id);

    expect(await repo.watchSubmittedReels().first, isEmpty);
  });

  test('lastUploadAt is null before any submission', () async {
    final repo = InMemoryReelSubmissionRepository();
    expect(await repo.lastUploadAt('uid_1'), isNull);
  });

  test('lastUploadAt reflects the most recent submission by that uid', () async {
    final repo = InMemoryReelSubmissionRepository();
    final before = DateTime.now();
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    final last = await repo.lastUploadAt('uid_1');

    expect(last, isNotNull);
    expect(last!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    expect(await repo.lastUploadAt('uid_2'), isNull);
  });

  test('submitReel persists the media type', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(
      _reel(mediaType: ReelMediaType.image),
      submittedByUid: 'uid_1',
    );
    final saved = (await repo.watchSubmittedReels().first).single;

    expect(saved.mediaType, ReelMediaType.image);
  });

  test('submitReel sets expiresAt roughly one cooldown period ahead', () async {
    final repo = InMemoryReelSubmissionRepository();
    final before = DateTime.now();
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    final saved = (await repo.watchSubmittedReels().first).single;

    expect(saved.expiresAt, isNotNull);
    final expected = before.add(reelUploadCooldown);
    expect(
      saved.expiresAt!.difference(expected).inSeconds.abs() < 2,
      isTrue,
    );
  });

  test('updateReel preserves the original expiresAt', () async {
    final repo = InMemoryReelSubmissionRepository();
    await repo.submitReel(_reel(), submittedByUid: 'uid_1');
    final saved = (await repo.watchSubmittedReels().first).single;

    await repo.updateReel(
      GameReel(
        id: saved.id,
        devName: saved.devName,
        devTag: saved.devTag,
        title: 'Yeni',
        caption: saved.caption,
        tags: saved.tags,
        accent: saved.accent,
        symbols: saved.symbols,
        hud: saved.hud,
        likes: saved.likes,
        gameUrl: saved.gameUrl,
        uploaderId: saved.uploaderId,
        comments: saved.comments,
      ),
    );

    final updated = (await repo.watchSubmittedReels().first).single;
    expect(updated.expiresAt, saved.expiresAt);
  });
}
