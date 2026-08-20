import 'package:neuroup/features/news/domain/entities/news_article.dart';

abstract class NewsRepository {
  Stream<List<NewsArticle>> watchAll();
  Stream<List<NewsArticle>> watchByCategory(NewsCategory category);
  Future<NewsArticle?> getById(String id);
  Future<int> refresh();
  Future<void> seedIfEmpty();

  /// Yeni bir haber ekler. `article.id` boşsa otomatik bir kimlik
  /// üretilir; oluşan/kullanılan kimliği döner.
  Future<String> createArticle(NewsArticle article);

  /// Var olan bir haberi (`article.id` ile) tamamen günceller.
  Future<void> updateArticle(NewsArticle article);

  Future<void> deleteArticle(String id);
}
