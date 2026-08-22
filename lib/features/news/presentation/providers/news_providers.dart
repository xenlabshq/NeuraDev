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

final StreamProviderFamily<List<NewsArticle>, NewsCategory>
newsByCategoryProvider = StreamProvider.family<List<NewsArticle>, NewsCategory>(
  (ref, category) async* {
    if (!Env.firebaseConfigured) {
      final repo = ref.read(newsRepositoryProvider);
      final list = await repo.watchByCategory(category).first;
      yield list;
      return;
    }
    await ref.read(newsRepositoryProvider).seedIfEmpty();
    yield* ref.read(newsRepositoryProvider).watchByCategory(category);
  },
);

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

/// Yönetim panelinin arşiv durumu — kategoriye göre filtrelenmiş,
/// sayfalanmış geçmiş haberler. Gerçek bir haber sitesi gibi "daha
/// fazla yükle" ile geriye doğru gezilebilir.
class NewsAdminArchiveState {
  const NewsAdminArchiveState({
    this.category,
    this.articles = const [],
    this.hasMore = true,
    this.loading = false,
  });

  final NewsCategory? category;
  final List<NewsArticle> articles;
  final bool hasMore;
  final bool loading;

  NewsAdminArchiveState copyWith({
    NewsCategory? category,
    bool clearCategory = false,
    List<NewsArticle>? articles,
    bool? hasMore,
    bool? loading,
  }) => NewsAdminArchiveState(
    category: clearCategory ? null : (category ?? this.category),
    articles: articles ?? this.articles,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
  );
}

class NewsAdminArchiveNotifier extends StateNotifier<NewsAdminArchiveState> {
  NewsAdminArchiveNotifier(this._ref) : super(const NewsAdminArchiveState()) {
    loadMore();
  }

  final Ref _ref;
  static const _pageSize = 20;

  Future<void> setCategory(NewsCategory? category) async {
    state = NewsAdminArchiveState(category: category);
    await loadMore();
  }

  /// Admin bir haber ekledi/güncelledi/sildi — arşivi baştan yükle ki
  /// yeni haber en üstte görünsün.
  Future<void> reload() async {
    state = state.copyWith(articles: [], hasMore: true);
    await loadMore();
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    final before = state.articles.isEmpty
        ? null
        : state.articles.last.publishedAt;
    final page = await _ref
        .read(newsRepositoryProvider)
        .fetchArchivePage(
          category: state.category,
          before: before,
          pageSize: _pageSize,
        );
    state = state.copyWith(
      articles: [...state.articles, ...page],
      hasMore: page.length == _pageSize,
      loading: false,
    );
  }
}

final newsAdminArchiveProvider =
    StateNotifierProvider.autoDispose<
      NewsAdminArchiveNotifier,
      NewsAdminArchiveState
    >((ref) => NewsAdminArchiveNotifier(ref));
