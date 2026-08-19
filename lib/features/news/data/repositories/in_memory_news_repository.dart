import 'dart:async';

import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';
import 'package:neuroup/features/news/data/news_seed.dart';

/// Demo mod için in-memory haber repository.
/// Firestore'a bağlanmadan, statik seed listesinden okur.
class InMemoryNewsRepository implements NewsRepository {
  InMemoryNewsRepository();

  List<NewsArticle> get _all => NewsSeed.all();

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

  List<NewsArticle> _sorted(List<NewsArticle> articles) {
    final list = [...articles];
    list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return list;
  }
}
