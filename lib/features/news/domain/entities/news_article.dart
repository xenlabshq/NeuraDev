import 'package:equatable/equatable.dart';

enum NewsCategory {
  education,
  technology,
  science,
  world,
  sports;

  String get label {
    switch (this) {
      case NewsCategory.education:
        return 'Eğitim';
      case NewsCategory.technology:
        return 'Teknoloji';
      case NewsCategory.science:
        return 'Bilim';
      case NewsCategory.world:
        return 'Dünya';
      case NewsCategory.sports:
        return 'Spor';
    }
  }

  String get emoji {
    switch (this) {
      case NewsCategory.education:
        return '📚';
      case NewsCategory.technology:
        return '💻';
      case NewsCategory.science:
        return '🔬';
      case NewsCategory.world:
        return '🌍';
      case NewsCategory.sports:
        return '⚽';
    }
  }
}

enum NewsPriority {
  critical,
  high,
  normal,
  info,
  positive;

  String get label {
    switch (this) {
      case NewsPriority.critical:
        return 'Son Dakika';
      case NewsPriority.high:
        return 'Önemli';
      case NewsPriority.normal:
        return 'Haber';
      case NewsPriority.info:
        return 'Bilgi';
      case NewsPriority.positive:
        return 'İlham';
    }
  }
}

class NewsArticle extends Equatable {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.source,
    required this.sourceUrl,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.isBreaking = false,
    this.priority = NewsPriority.normal,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String source;
  final String sourceUrl;
  final NewsCategory category;
  final DateTime publishedAt;
  final String? imageUrl;
  final bool isBreaking;
  final NewsPriority priority;

  Duration get age => DateTime.now().difference(publishedAt);

  String get ageLabel {
    final a = age;
    if (a.inMinutes < 60) return '${a.inMinutes} dk önce';
    if (a.inHours < 24) return '${a.inHours} sa önce';
    if (a.inDays < 7) return '${a.inDays} gün önce';
    return '${(a.inDays / 7).floor()} hafta önce';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        body,
        source,
        sourceUrl,
        category,
        publishedAt,
        imageUrl,
        isBreaking,
        priority,
      ];
}
