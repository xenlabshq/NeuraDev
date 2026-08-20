import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reels/data/in_memory_reel_submission_repository.dart';
import 'package:neuroup/features/reels/domain/entities/game_reel.dart';

GameReel _reel({String title = 'Test Oyunu'}) => GameReel(
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
}
