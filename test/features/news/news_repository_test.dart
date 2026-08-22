import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/news/data/repositories/news_repository_impl.dart';
import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';
import 'package:neuroup/features/news/presentation/utils/news_labels.dart';
import 'package:neuroup/l10n/gen/app_localizations.dart';

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

  test('fetchArchivePage paginates newest-first and filters by category', () async {
    await repo.seedIfEmpty();
    final firstPage = await repo.fetchArchivePage(pageSize: 5);
    expect(firstPage.length, 5);

    final secondPage = await repo.fetchArchivePage(
      before: firstPage.last.publishedAt,
      pageSize: 5,
    );
    expect(secondPage, isNotEmpty);
    expect(
      secondPage.every(
        (a) => a.publishedAt.isBefore(firstPage.last.publishedAt),
      ),
      isTrue,
    );

    final eduPage = await repo.fetchArchivePage(
      category: NewsCategory.education,
      pageSize: 50,
    );
    expect(eduPage, isNotEmpty);
    for (final a in eduPage) {
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
    final l10n = lookupAppLocalizations(const Locale('tr'));
    expect(article.relativeAge(l10n), '5 dk önce');
  });

  test('seedIfEmpty is idempotent', () async {
    await repo.seedIfEmpty();
    final first = await repo.watchAll().first;
    await repo.seedIfEmpty();
    final second = await repo.watchAll().first;
    expect(first.length, second.length);
  });

  group('admin write operations', () {
    NewsArticle draft({String id = ''}) => NewsArticle(
      id: id,
      title: 'Yeni haber',
      summary: 'özet',
      body: 'gövde metni',
      source: 'Neuroup Editör',
      sourceUrl: '',
      category: NewsCategory.technology,
      publishedAt: DateTime(2026, 1, 1),
      priority: NewsPriority.high,
    );

    test('createArticle assigns an id and persists all fields', () async {
      final id = await repo.createArticle(draft());
      expect(id, isNotEmpty);

      final saved = await repo.getById(id);
      expect(saved, isNotNull);
      expect(saved!.title, 'Yeni haber');
      expect(saved.category, NewsCategory.technology);
      // Regresyon guard: priority alanı önceden Firestore'a hiç
      // yazılmıyordu, her zaman 'normal'e geri dönüyordu.
      expect(saved.priority, NewsPriority.high);
    });

    test('createArticle respects an explicitly provided id', () async {
      final id = await repo.createArticle(draft(id: 'ozel-id'));
      expect(id, 'ozel-id');
      expect(await repo.getById('ozel-id'), isNotNull);
    });

    test('updateArticle overwrites an existing article', () async {
      final id = await repo.createArticle(draft());
      final saved = (await repo.getById(id))!;
      await repo.updateArticle(
        NewsArticle(
          id: id,
          title: 'Güncellenmiş başlık',
          summary: saved.summary,
          body: saved.body,
          source: saved.source,
          sourceUrl: saved.sourceUrl,
          category: saved.category,
          publishedAt: saved.publishedAt,
          priority: saved.priority,
        ),
      );
      final updated = await repo.getById(id);
      expect(updated!.title, 'Güncellenmiş başlık');
    });

    test('deleteArticle removes the article', () async {
      final id = await repo.createArticle(draft());
      await repo.deleteArticle(id);
      expect(await repo.getById(id), isNull);
    });
  });
}
