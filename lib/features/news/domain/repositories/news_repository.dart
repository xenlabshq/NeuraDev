import 'package:neuroup/features/news/domain/entities/news_article.dart';

abstract class NewsRepository {
  Stream<List<NewsArticle>> watchAll();
  Stream<List<NewsArticle>> watchByCategory(NewsCategory category);
  Future<NewsArticle?> getById(String id);
  Future<int> refresh();
  Future<void> seedIfEmpty();

  /// Yönetim panelindeki arşiv görünümü için sayfalanmış sorgu — gerçek
  /// bir haber sitesi gibi geçmişe doğru "daha fazla yükle" ile
  /// gezilebilir. [category] null ise tüm kategoriler, [before]
  /// verilirse o tarihten daha eski haberler getirilir (bir sonraki
  /// sayfa için önceki sayfanın en eski makalesinin `publishedAt`ı
  /// gönderilir).
  Future<List<NewsArticle>> fetchArchivePage({
    NewsCategory? category,
    DateTime? before,
    int pageSize = 20,
  });

  /// Yeni bir haber ekler. `article.id` boşsa otomatik bir kimlik
  /// üretilir; oluşan/kullanılan kimliği döner.
  Future<String> createArticle(NewsArticle article);

  /// Var olan bir haberi (`article.id` ile) tamamen günceller.
  Future<void> updateArticle(NewsArticle article);

  Future<void> deleteArticle(String id);
}
