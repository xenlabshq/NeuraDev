import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/reels/data/in_memory_reels_repository.dart';

void main() {
  late InMemoryReelsRepository repo;

  setUp(() => repo = InMemoryReelsRepository());

  test('getAll returns the 5 seeded reels', () {
    expect(repo.getAll().length, 5);
  });

  test('getById returns the matching reel', () {
    final first = repo.getAll().first;
    expect(repo.getById(first.id)?.id, first.id);
  });

  test('getById returns null for an unknown id', () {
    expect(repo.getById('does-not-exist'), isNull);
  });

  test('toggleLike flips liked and adjusts the like count', () {
    final before = repo.getAll().first;
    final afterLike = repo.toggleLike(before.id);
    expect(afterLike.liked, !before.liked);
    expect(afterLike.likes, before.likes + (afterLike.liked ? 1 : -1));

    final afterUnlike = repo.toggleLike(before.id);
    expect(afterUnlike.liked, before.liked);
    expect(afterUnlike.likes, before.likes);
  });

  test('toggleSave flips saved without touching other fields', () {
    final before = repo.getAll().first;
    final after = repo.toggleSave(before.id);
    expect(after.saved, !before.saved);
    expect(after.liked, before.liked);
  });

  test('toggleFollow flips following', () {
    final before = repo.getAll().first;
    final after = repo.toggleFollow(before.id);
    expect(after.following, !before.following);
  });

  test('addComment prepends a new comment from the current user', () {
    final before = repo.getAll().first;
    final after = repo.addComment(before.id, 'harika!');
    expect(after.comments.length, before.comments.length + 1);
    expect(after.comments.first.text, 'harika!');
    expect(after.comments.first.isMe, isTrue);
  });

  test('mutations persist across getAll calls (in-memory state)', () {
    final id = repo.getAll().first.id;
    repo.toggleLike(id);
    expect(repo.getById(id)!.liked, isTrue);
  });

  test('toggleLike on an unknown id throws', () {
    expect(() => repo.toggleLike('nope'), throwsStateError);
  });

  test('fetchMore returns remaining items past the offset', () async {
    final page = await repo.fetchMore(offset: 3, pageSize: 10);
    expect(page.length, 2);
    expect(page.first.id, repo.getAll()[3].id);
  });

  test('fetchMore returns an empty list once the offset exceeds all items', () async {
    final page = await repo.fetchMore(offset: 5, pageSize: 10);
    expect(page, isEmpty);
  });
}
