import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../data/services/messaging_service.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';

/// Vitrin/Reels tarzında yeniden tasarlanmış haber sayfası.
/// - Gradient hero header (koyu indigo → mor)
/// - Glassmorphism featured card
/// - Vitrin'deki gibi öncelik rozeti (kırmızı/turuncu/mavi/gri/yeşil)
/// - Yatay kaydırmalı kategori filtre chip'leri
/// - Her kart glassmorphism (yarı saydam, blur, accent border)
class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  NewsCategory? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read<MessagingService>(firebaseMessagingServiceProvider)
          .subscribeToDefaultTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncNews = _selected == null
        ? ref.watch(newsStreamProvider)
        : ref.watch(newsByCategoryProvider(_selected!));

    return Scaffold(
      // News her iki temada da karanlık tasarımlı (mor-siyah gradient).
      // iMessage haberler tarzı.
      backgroundColor: const Color(0xFF0A0812),
      body: Stack(
        children: [
          // Arka plan gradient (koyu)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1428),
                    Color(0xFF0A0812),
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              _NewsHeader(),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'Tümü',
                        selected: _selected == null,
                        color: AppColors.accent,
                        onTap: () => setState(() => _selected = null),
                      ),
                      ...NewsCategory.values.map((c) => _CategoryChip(
                            label: '${c.emoji} ${c.label}',
                            selected: _selected == c,
                            color: _colorForCategory(c),
                            onTap: () => setState(() => _selected = c),
                          )),
                    ],
                  ),
                ),
              ),
              asyncNews.when(
                loading: () => const SliverPadding(
                  padding: EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(child: _NewsLoadingList()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('Hata: $e',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                data: (articles) {
                  if (articles.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.article_outlined,
                        title: 'Haber yok',
                        message:
                            'Bu kategoride henüz haber bulunmuyor.',
                      ),
                    );
                  }
                  final priorityOrder = {
                    NewsPriority.critical: 0,
                    NewsPriority.high: 1,
                    NewsPriority.normal: 2,
                    NewsPriority.info: 3,
                    NewsPriority.positive: 4,
                  };
                  final sorted = [...articles]..sort((a, b) {
                      final pa = priorityOrder[a.priority] ?? 5;
                      final pb = priorityOrder[b.priority] ?? 5;
                      if (pa != pb) return pa.compareTo(pb);
                      return b.publishedAt.compareTo(a.publishedAt);
                    });
                  final breaking =
                      sorted.where((a) => a.isBreaking).toList();
                  final featured = sorted.first;
                  final rest = sorted
                      .skip(breaking.isNotEmpty ? 0 : 1)
                      .toList();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (breaking.isNotEmpty) ...[
                          _BreakingBanner(articles: breaking),
                          const SizedBox(height: 16),
                        ],
                        _FeaturedArticle(
                          article: featured,
                          onTap: () =>
                              context.push('/news/${featured.id}'),
                        ),
                        const SizedBox(height: 20),
                        if (rest.length > 1) ...[
                          const Padding(
                            padding:
                                EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Diğer Haberler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          for (var i = 1; i < rest.length; i++) ...[
                            _NewsCard(
                              article: rest[i],
                              onTap: () =>
                                  context.push('/news/${rest[i].id}'),
                            ),
                            if (i < rest.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorForCategory(NewsCategory c) => switch (c) {
        NewsCategory.education => AppColors.violet,
        NewsCategory.technology => AppColors.info,
        NewsCategory.science => AppColors.success,
        NewsCategory.world => AppColors.warning,
        NewsCategory.sports => AppColors.orange,
      };
}

class _NewsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent,
              AppColors.violet,
              const Color(0xFF1A1428),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: 40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.article_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Haberler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dünyadan ve eğitimden son dakika',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? color
                    : Colors.white.withValues(alpha: 0.15),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakingBanner extends StatelessWidget {
  const _BreakingBanner({required this.articles});
  final List<NewsArticle> articles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.error, AppColors.orange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flash_on_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SON DAKİKA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  articles.first.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedArticle extends StatelessWidget {
  const _FeaturedArticle({required this.article, required this.onTap});
  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(article.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero görsel alanı (gradient placeholder)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.5)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: article.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _FeaturedEmoji(
                            emoji: article.category.emoji,
                          ),
                          placeholder: (_, __) => _FeaturedEmoji(
                            emoji: article.category.emoji,
                          ),
                        ),
                      )
                    : _FeaturedEmoji(emoji: article.category.emoji),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SmallChip(
                          label: article.category.label,
                          color: color,
                        ),
                        _PriorityBadgeInline(priority: article.priority),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          article.ageLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForCategory(NewsCategory c) => switch (c) {
        NewsCategory.education => AppColors.violet,
        NewsCategory.technology => AppColors.info,
        NewsCategory.science => AppColors.success,
        NewsCategory.world => AppColors.warning,
        NewsCategory.sports => AppColors.orange,
      };
}

class _FeaturedEmoji extends StatelessWidget {
  const _FeaturedEmoji({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.violet],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 64)),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onTap});
  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (article.category) {
      NewsCategory.education => AppColors.violet,
      NewsCategory.technology => AppColors.info,
      NewsCategory.science => AppColors.success,
      NewsCategory.world => AppColors.warning,
      NewsCategory.sports => AppColors.orange,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(article.category.emoji,
                    style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _SmallChip(
                            label: article.category.label, color: color),
                        _PriorityBadgeInline(priority: article.priority),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.ageLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PriorityBadgeInline extends StatelessWidget {
  const _PriorityBadgeInline({required this.priority});
  final NewsPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      NewsPriority.critical => AppColors.error,
      NewsPriority.high => AppColors.orange,
      NewsPriority.normal => AppColors.info,
      NewsPriority.info => const Color(0xFF6E6390),
      NewsPriority.positive => AppColors.success,
    };
    final label = switch (priority) {
      NewsPriority.critical => '🔴',
      NewsPriority.high => '🟠',
      NewsPriority.normal => '🔵',
      NewsPriority.info => '⚪',
      NewsPriority.positive => '🟢',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _NewsLoadingList extends StatelessWidget {
  const _NewsLoadingList();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Skeleton(width: double.infinity, height: 200),
        SizedBox(height: 16),
        Skeleton(width: double.infinity, height: 100),
        SizedBox(height: 10),
        Skeleton(width: double.infinity, height: 100),
      ],
    );
  }
}