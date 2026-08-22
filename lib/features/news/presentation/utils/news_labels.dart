import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/news_article.dart';

/// Kategori/öncelik enum'larının çevrilebilir etiketleri — domain
/// katmanı l10n'a bağımlı olmasın diye burada, presentation'da tutulur.
extension NewsCategoryLabel on NewsCategory {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    NewsCategory.education => l10n.newsCategoryEducation,
    NewsCategory.technology => l10n.newsCategoryTechnology,
    NewsCategory.science => l10n.newsCategoryScience,
    NewsCategory.world => l10n.newsCategoryWorld,
    NewsCategory.sports => l10n.newsCategorySports,
  };
}

extension NewsPriorityLabel on NewsPriority {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    NewsPriority.critical => l10n.newsPriorityCritical,
    NewsPriority.high => l10n.newsPriorityHigh,
    NewsPriority.normal => l10n.newsPriorityNormal,
    NewsPriority.info => l10n.newsPriorityInfo,
    NewsPriority.positive => l10n.newsPriorityPositive,
  };
}

extension NewsArticleAge on NewsArticle {
  /// "5 dk önce" / "5 min ago" gibi göreli yaş etiketi — eskiden
  /// domain entity'de sabit Türkçe metindi, artık locale'e göre üretilir.
  String relativeAge(AppLocalizations l10n) {
    final a = age;
    if (a.inMinutes < 60) return l10n.timeAgoMinutes(a.inMinutes);
    if (a.inHours < 24) return l10n.timeAgoHours(a.inHours);
    if (a.inDays < 7) return l10n.timeAgoDays(a.inDays);
    return l10n.timeAgoWeeks((a.inDays / 7).floor());
  }
}
