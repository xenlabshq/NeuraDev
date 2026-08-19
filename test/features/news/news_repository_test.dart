import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/news/data/repositories/news_repository_impl.dart';
import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';

void main() {
  late NewsRepository repo;
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NewsRepositoryImpl(db);
  });

  test('seedIfEmpty populates articles', () async {
    await repo.seedIfEmpty();
    final stream = repo.watchAll();
    final articles = await stream.first;
    expect(articles, isNotEmpty);
    expect(articles.length, greaterThan(3));
  });

  test('articles are ordered by publishedAt descending', () async {
    await repo.seedIfEmpty();
    final articles = await repo.watchAll().first;
    for (var i = 0; i < articles.length - 1; i++) {
      expect(
        articles[i].publishedAt.isAfter(articles[i + 1].publishedAt) ||
            articles[i].publishedAt.isAtSameMomentAs(
              articles[i + 1].publishedAt,
            ),
        isTrue,
      );
    }
  });

  test('watchByCategory filters correctly', () async {
    await repo.seedIfEmpty();
    final edu = await repo.watchByCategory(NewsCategory.education).first;
    expect(edu, isNotEmpty);
    for (final a in edu) {
      expect(a.category, NewsCategory.education);
    }
  });

  test('NewsArticle age label', () {
    final article = NewsArticle(
      id: 'x',
      title: 't',
      summary: 's',
      body: 'b',
      source: 'src',
      sourceUrl: '',
      category: NewsCategory.world,
      publishedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    expect(article.ageLabel, '5 dk önce');
  });

  test('seedIfEmpty is idempotent', () async {
    await repo.seedIfEmpty();
    final first = await repo.watchAll().first;
    await repo.seedIfEmpty();
    final second = await repo.watchAll().first;
    expect(first.length, second.length);
  });
}
