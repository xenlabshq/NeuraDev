import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';
import 'package:neuroup/features/news/data/news_seed.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _news => _db.collection('news');

  @override
  Stream<List<NewsArticle>> watchAll() {
    return _news
        .orderBy('publishedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<NewsArticle>> watchByCategory(NewsCategory category) {
    // Bilinçli olarak `where('category', ...)` + `orderBy('publishedAt', ...)`
    // birleşimi kullanılmıyor — Firestore bu kombinasyon için composite
    // index ister, tanımlı değilse sorgu `failed-precondition` hatasıyla
    // hemen patlar (kategori sekmesine her tıklamada "Haberler
    // yüklenemedi" hatası). Bunun yerine tek alanlı `orderBy` (index
    // gerektirmez, `watchAll()` ile aynı) kullanılıp kategori filtresi
    // istemci tarafında uygulanıyor.
    return _news
        .orderBy('publishedAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(_fromDoc)
              .where((a) => a.category == category)
              .toList(),
        );
  }

  @override
  Future<List<NewsArticle>> fetchArchivePage({
    NewsCategory? category,
    DateTime? before,
    int pageSize = 20,
  }) async {
    // Aynı sebeple (bkz. watchByCategory) burada da composite index
    // gerektirecek bir `where(category)` + `orderBy` + `where(before)`
    // birleşimi kullanılmıyor — tek alanlı orderBy + tarih filtresi
    // (ikisi de aynı alan: publishedAt, index gerektirmez), kategori
    // filtresi istemci tarafında uygulanır.
    Query<Map<String, dynamic>> query = _news.orderBy(
      'publishedAt',
      descending: true,
    );
    if (before != null) {
      query = query.where(
        'publishedAt',
        isLessThan: Timestamp.fromDate(before),
      );
    }
    final snap = await query.limit(pageSize).get();
    final articles = snap.docs.map(_fromDoc).toList();
    if (category == null) return articles;
    return articles.where((a) => a.category == category).toList();
  }

  @override
  Future<NewsArticle?> getById(String id) async {
    final doc = await _news.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  @override
  Future<int> refresh() async {
    final existing = await _news.limit(1).get();
    if (existing.docs.isEmpty) {
      await seedIfEmpty();
      return NewsSeed.all().length;
    }
    LoggerService.info('news refresh: no-op (using cache)');
    return 0;
  }

  @override
  Future<void> seedIfEmpty() async {
    final existing = await _news.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    LoggerService.info('Seeding news collection...');
    final batch = _db.batch();
    for (final article in NewsSeed.all()) {
      final doc = _news.doc(article.id);
      batch.set(doc, _toMap(article));
    }
    await batch.commit();
    LoggerService.debug('seeded ${NewsSeed.all().length} news articles');
  }

  @override
  Future<String> createArticle(NewsArticle article) async {
    final doc = article.id.isEmpty ? _news.doc() : _news.doc(article.id);
    await doc.set(_toMap(article));
    return doc.id;
  }

  @override
  Future<void> updateArticle(NewsArticle article) async {
    await _news.doc(article.id).set(_toMap(article));
  }

  @override
  Future<void> deleteArticle(String id) async {
    await _news.doc(id).delete();
  }

  NewsArticle _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NewsArticle(
      id: doc.id,
      title: data['title'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      body: data['body'] as String? ?? '',
      source: data['source'] as String? ?? 'Bilinmiyor',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      category: NewsCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => NewsCategory.world,
      ),
      publishedAt:
          (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      isBreaking: data['isBreaking'] as bool? ?? false,
      priority: NewsPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => NewsPriority.normal,
      ),
    );
  }

  Map<String, dynamic> _toMap(NewsArticle a) => {
    'title': a.title,
    'summary': a.summary,
    'body': a.body,
    'source': a.source,
    'sourceUrl': a.sourceUrl,
    'category': a.category.name,
    'publishedAt': a.publishedAt,
    'imageUrl': a.imageUrl,
    'isBreaking': a.isBreaking,
    'priority': a.priority.name,
  };
}
