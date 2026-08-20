import 'dart:async';

import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';
import 'package:neuroup/features/news/data/news_seed.dart';

/// Demo mod için in-memory haber repository.
/// Firestore'a bağlanmadan, seed listesinden başlar; create/update/delete
/// bu oturum boyunca bellekte kalıcıdır (uygulama kapanınca sıfırlanır).
class InMemoryNewsRepository implements NewsRepository {
  InMemoryNewsRepository() : _all = List.of(NewsSeed.all());

  final List<NewsArticle> _all;
  int _autoId = 0;

  @override
  Stream<List<NewsArticle>> watchAll() {
    return Stream.value(_sorted(_all));
  }

  @override
  Stream<List<NewsArticle>> watchByCategory(NewsCategory category) {
    return Stream.value(
      _sorted(_all.where((a) => a.category == category).toList()),
    );
  }

  @override
  Future<NewsArticle?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (final a in _all) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<int> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _all.length;
  }

  @override
  Future<void> seedIfEmpty() async {
    // Demo modda her zaman dolu.
  }

  @override
  Future<String> createArticle(NewsArticle article) async {
    final id = article.id.isEmpty ? 'demo_news_${_autoId++}' : article.id;
    _all.add(
      NewsArticle(
        id: id,
        title: article.title,
        summary: article.summary,
        body: article.body,
        source: article.source,
        sourceUrl: article.sourceUrl,
        category: article.category,
        publishedAt: article.publishedAt,
        imageUrl: article.imageUrl,
        isBreaking: article.isBreaking,
        priority: article.priority,
      ),
    );
    return id;
  }

  @override
  Future<void> updateArticle(NewsArticle article) async {
    final i = _all.indexWhere((a) => a.id == article.id);
    if (i >= 0) _all[i] = article;
  }

  @override
  Future<void> deleteArticle(String id) async {
    _all.removeWhere((a) => a.id == id);
  }

  List<NewsArticle> _sorted(List<NewsArticle> articles) {
    final list = [...articles];
    list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return list;
  }
}
