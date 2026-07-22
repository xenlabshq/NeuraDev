import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/core/env/env.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/news/data/repositories/in_memory_news_repository.dart';
import 'package:neuroup/features/news/data/repositories/news_repository_impl.dart';
import 'package:neuroup/features/news/domain/entities/news_article.dart';
import 'package:neuroup/features/news/domain/repositories/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  if (!Env.firebaseConfigured) {
    // Demo modda Firestore'a bağlanma — in-memory repo kullan
    return InMemoryNewsRepository();
  }
  return NewsRepositoryImpl(ref.watch(firestoreProvider));
});

final newsStreamProvider = StreamProvider<List<NewsArticle>>((ref) async* {
  if (!Env.firebaseConfigured) {
    // Demo: tüm haberleri direkt döndür (her stream'de yeniden)
    final repo = ref.read(newsRepositoryProvider);
    final list = await repo.watchAll().first;
    yield list;
    return;
  }
  await ref.read(newsRepositoryProvider).seedIfEmpty();
  yield* ref.read(newsRepositoryProvider).watchAll();
});

final StreamProviderFamily<List<NewsArticle>, NewsCategory> newsByCategoryProvider =
    StreamProvider.family<List<NewsArticle>, NewsCategory>((ref, category) {
  return ref.read(newsRepositoryProvider).watchByCategory(category);
});

final FutureProviderFamily<NewsArticle?, String> newsArticleProvider =
    FutureProvider.family<NewsArticle?, String>((ref, id) {
  return ref.read(newsRepositoryProvider).getById(id);
});

final newsRefreshControllerProvider = Provider<NewsRefreshController>(
  NewsRefreshController.new,
);

class NewsRefreshController {
  NewsRefreshController(this._ref);
  final Ref _ref;

  Future<int> refresh() async {
    _ref.invalidate(newsStreamProvider);
    return _ref.read(newsRepositoryProvider).refresh();
  }
}