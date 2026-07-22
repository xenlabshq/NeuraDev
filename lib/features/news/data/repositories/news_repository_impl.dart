import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';
import 'package:neuroup/features/news/data/news_seed.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _news =>
      _db.collection('news');

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
    return _news
        .where('category', isEqualTo: category.name)
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
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
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      isBreaking: data['isBreaking'] as bool? ?? false,
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
      };
}