import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/home_shell.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider;
import '../../data/services/messaging_service.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import '../utils/news_labels.dart';
import 'news_admin_page.dart';

/// Vitrin/Reels tarzında yeniden tasarlanmış haber sayfası.
///
/// Tasarım prensipleri:
/// - Koyu mor-siyah gradient arka plan (tema bağımsız)
/// - Hero'da tarih + başlık + alt başlık + sayaç
/// - Glassmorphism kategori filtre chip'leri (yatay scroll)
/// - "Son Dakika" varsa özel banner (kırmızı-turuncu gradient)
/// - Featured büyük kart (gradient hero görsel + başlık + özet + meta)
/// - Standart liste kartları (yatay thumbnail + başlık + meta)
/// - Pull-to-refresh
/// - Tüm içerik yüzen alt barın üstünde biter (`_bottomClearance`)
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

  /// Yüzen alt bar + alt safe area için gereken minimum padding.
  /// Tek kaynak — tüm bottom padding buradan türetilir.
  double get _bottomClearance =>
      kBottomBarHeight + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final asyncNews = _selected == null
        ? ref.watch(newsStreamProvider)
        : ref.watch(newsByCategoryProvider(_selected!));
    final user = ref.watch(currentAuthUserProvider);
    final canManageNews = user?.role.isSupportStaff ?? false;

    return Scaffold(
      floatingActionButton: canManageNews
          ? Padding(
              padding: const EdgeInsets.only(bottom: kBottomBarHeight),
              child: FloatingActionButton.extended(
                heroTag: 'news-admin-fab',
                backgroundColor: AppColors.accent,
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                label: const Text(
                  'Haber Yönetimi',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewsAdminPage(),
                  ),
                ),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Stack(
              children: [
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 280,
                      child: _NewsSidebar(
                        selected: _selected,
                        onSelect: (c) => setState(() => _selected = c),
                        colorFor: _colorForCategory,
                      ),
                    ),
                    Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.accent,
                        backgroundColor: const Color(0xFF1A1428),
                        onRefresh: _onRefresh,
                        child: _buildScrollable(
                          context,
                          asyncNews,
                          showCategoryStrip: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return Stack(
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
              RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: const Color(0xFF1A1428),
                onRefresh: _onRefresh,
                child: _buildScrollable(
                  context,
                  asyncNews,
                  showCategoryStrip: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(newsStreamProvider);
    if (_selected != null) {
      ref.invalidate(newsByCategoryProvider(_selected!));
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Widget _buildScrollable(
    BuildContext context,
    AsyncValue<List<NewsArticle>> asyncNews, {
    required bool showCategoryStrip,
  }) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        _NewsHeader(
          selectedCategory: _selected,
          onCategoryPicked: (c) => setState(() => _selected = c),
          colorFor: _colorForCategory,
        ),
        if (showCategoryStrip)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: l10n.newsAllCategory,
                    selected: _selected == null,
                    color: AppColors.accent,
                    onTap: () => setState(() => _selected = null),
                  ),
                  ...NewsCategory.values.map(
                    (c) => _CategoryChip(
                      label: '${c.emoji} ${c.localizedLabel(l10n)}',
                      selected: _selected == c,
                      color: _colorForCategory(c),
                      onTap: () => setState(() => _selected = c),
                    ),
                  ),
                ],
              ),
            ),
          ),
        asyncNews.when(
          loading: () => SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, _bottomClearance),
            sliver: const SliverToBoxAdapter(child: _NewsLoadingList()),
          ),
          error: (e, _) => SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, _bottomClearance),
            sliver: SliverToBoxAdapter(
              child: _NewsError(
                message: '$e',
                onRetry: () {
                  ref.invalidate(newsStreamProvider);
                  if (_selected != null) {
                    ref.invalidate(newsByCategoryProvider(_selected!));
                  }
                },
              ),
            ),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, _bottomClearance),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.article_outlined,
                    title: l10n.newsEmptyTitle,
                    message: l10n.newsEmptyMessage,
                    actionLabel: l10n.newsShowAllAction,
                    onAction: () => setState(() => _selected = null),
                  ),
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
            final sorted = [...articles]
              ..sort((a, b) {
                final pa = priorityOrder[a.priority] ?? 5;
                final pb = priorityOrder[b.priority] ?? 5;
                if (pa != pb) return pa.compareTo(pb);
                return b.publishedAt.compareTo(a.publishedAt);
              });
            final breaking = sorted.where((a) => a.isBreaking).toList();
            final featured = sorted.first;
            final rest = sorted.skip(breaking.isNotEmpty ? 0 : 1).toList();

            final items = <Widget>[];

            if (breaking.isNotEmpty) {
              items.add(_BreakingBanner(articles: breaking));
              items.add(const SizedBox(height: 14));
            }
            items.add(
              _FeaturedArticle(
                article: featured,
                onTap: () => context.push('/news/${featured.id}'),
              ),
            );
            if (rest.length > 1) {
              items.add(const SizedBox(height: 20));
              items.add(
                _SectionHeader(
                  title: l10n.newsOtherArticlesTitle,
                  count: rest.length - 1,
                ),
              );
              items.add(const SizedBox(height: 4));
              for (var i = 1; i < rest.length; i++) {
                items.add(
                  _NewsCard(
                    article: rest[i],
                    onTap: () => context.push('/news/${rest[i].id}'),
                  ),
                );
                if (i < rest.length - 1) {
                  items.add(const SizedBox(height: 10));
                }
              }
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, _bottomClearance),
              sliver: SliverList(
                delegate: SliverChildListDelegate(items),
              ),
            );
          },
        ),
      ],
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

/// Geniş ekran (>= 900px) için sol sidebar: dikey kategori listesi
/// + trend istatistik kartı. Glassmorphism stili, mobile yatay
/// şeridin aynı renklerini paylaşır. SingleChildScrollView ile sarılı
/// böylece içerik sığmazsa kendi içinde scroll eder.
class _NewsSidebar extends StatelessWidget {
  const _NewsSidebar({
    required this.selected,
    required this.onSelect,
    required this.colorFor,
  });

  final NewsCategory? selected;
  final ValueChanged<NewsCategory?> onSelect;
  final Color Function(NewsCategory) colorFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar başlığı
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.article_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.newsCategoriesTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tümü chip
            _SidebarCategoryTile(
              label: l10n.newsAllCategory,
              emoji: '📰',
              color: AppColors.accent,
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(height: 6),
            // Kategoriler
            for (final c in NewsCategory.values) ...[
              _SidebarCategoryTile(
                label: c.localizedLabel(l10n),
                emoji: c.emoji,
                color: colorFor(c),
                selected: selected == c,
                onTap: () => onSelect(c),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 16),
            const Divider(
              color: Color(0x14FFFFFF),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 16),
            // Trend istatistik kartı
            const _SidebarStatsCard(),
          ],
        ),
      ),
    );
  }
}

class _SidebarCategoryTile extends StatelessWidget {
  const _SidebarCategoryTile({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFD9D2EC),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_rounded, color: color, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarStatsCard extends StatelessWidget {
  const _SidebarStatsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.newsTrendTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statRow(l10n.newsStatToday, '5', AppColors.accent),
          const SizedBox(height: 6),
          _statRow(l10n.newsStatThisWeek, '24', AppColors.info),
          const SizedBox(height: 6),
          _statRow(l10n.newsStatTotal, '128', AppColors.success),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB8AED1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Hero başlık — `expandedHeight: 240`. Glassmorphism rozet + başlık +
/// alt başlık + tarih/sayaç. SliverAppBar toolbar (~56px) alanı
/// düşüldükten sonra kalan alan tüm metin + ölçek büyütmelerini
/// karşılayacak kadar yüksek tutulur; böylece RenderFlex overflow
/// vermez. `Column(mainAxisAlignment: end, min)` altta hizalar.
class _NewsHeader extends StatelessWidget {
  const _NewsHeader({
    this.selectedCategory,
    required this.onCategoryPicked,
    required this.colorFor,
  });
  final NewsCategory? selectedCategory;
  final ValueChanged<NewsCategory?> onCategoryPicked;
  final Color Function(NewsCategory) colorFor;

  String _todayLabel(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final months = isEnglish
        ? const [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ]
        : const [
            'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
            'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
          ];
    final days = isEnglish
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Kategori label'ı artık hero header altında gösterilmiyor —
    // kullanıcı "Eğitim / Bilim gibi yazılar çıkmasın" istedi.
    // Seçim bilgisi zaten bottom sheet'teki bubble pill'de ve
    // (wide layout'ta) sidebar'da görünüyor; hero'da tekrarı
    // görsel kirlilik yaratıyordu.
    return SliverAppBar(
      expandedHeight: 200,
      collapsedHeight: 64,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      // Title collapsed toolbar'da sabit görünür — kaydırınca
      // "Haberler" + tarih pill kaybolmaz. Expanded durumda ise
      // flexibleSpace içindeki büyük başlık üstte kaplandığı için
      // buradaki başlık görünmez; doğal davranış.
      title: Row(
        children: [
          // Sol grup: icon pill + tarih pill. mainAxisSize.min ile
          // içeriğe göre genişler, sağa doğru yayılmaz.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _todayLabel(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Sağ: bubble-shaped kategori reveal container. Tıklanınca
          // tüm kategorileri listeleyen bir bottom sheet açar; seçim
          // parent callback'e iletilir. Eski konum: sol gruba sabit
          // gap ile yapışık, kendi intrinsic genişliğinde; iki yana
          // genişleyip iç içe girme yapmaz.
          _CategoryRevealBubble(
            selected: selectedCategory,
            colorFor: colorFor,
            onSelect: onCategoryPicked,
          ),
        ],
      ),
      titleSpacing: 16,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent,
              AppColors.violet,
              Color(0xFF1A1428),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: 30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Expanded alanda büyük "Haberler" başlığı + opsiyonel
            // kategori alt başlığı. Yatayda tam ortalanır, böylece
            // toolbar'daki tarih pill ile aynı sol hizada olup
            // görsel çakışma yaratmaz. dikey olarak `bottom: 12`
            // ile alt kenardan yapışık — toolbar (64px) üstte
            // kaplandığı için tarihle dikey çakışma yok.
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flexible sarmalayıcı kaldırıldı: Container artık
                  // intrinsic (auto) width'inde — sadece içerideki Text
                  // + padding kadar. Column crossAxisAlignment.end
                  // ile bu küçük Container sağa yaslanır. Uzun başlık
                  // gelirse Text'in maxLines:2 + ellipsis'i keser,
                  // Container Column genişliğiyle sınırlanır.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      l10n.navNews,
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : Colors.white.withValues(alpha: 0.15),
                width: selected ? 1.5 : 1,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final l10n = AppLocalizations.of(context);
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
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.newsBreakingLabel,
                  style: const TextStyle(
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

/// Bölüm başlığı — başlık + sayı rozeti. Glassmorphism arka plan.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Büyük featured kart. 140 px hero (cap) + 14 px padding içinde
/// chips + 2-line title + 2-line summary + meta. Tüm metinlerde
/// `maxLines` + `ellipsis` — herhangi bir textScale'de overflow yok.
class _FeaturedArticle extends StatelessWidget {
  const _FeaturedArticle({required this.article, required this.onTap});
  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      article.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: article.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _FeaturedEmoji(
                                emoji: article.category.emoji,
                              ),
                              placeholder: (_, __) => _FeaturedEmoji(
                                emoji: article.category.emoji,
                              ),
                            )
                          : _FeaturedEmoji(emoji: article.category.emoji),
                      // Alt gradient overlay (okunabilirlik)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Sağ alt köşe: ÖNE ÇIKAN rozeti
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: color, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                l10n.newsFeaturedLabel,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _SmallChip(
                          label: article.category.localizedLabel(l10n),
                          color: color,
                        ),
                        _PriorityBadgeInline(priority: article.priority),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            article.relativeAge(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.readingTimeMinutes(
                              article.body.split(' ').length ~/ 200 + 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.violet],
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 56)),
    );
  }
}

/// Yatay thumbnail (60x60) + metin. Row'da `crossAxisAlignment: start`.
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onTap});
  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          padding: const EdgeInsets.all(12),
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
                child: Text(
                  article.category.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _SmallChip(
                          label: article.category.localizedLabel(l10n),
                          color: color,
                        ),
                        _PriorityBadgeInline(priority: article.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            article.relativeAge(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

/// Hata durumu için kompakt geri bildirim.
class _NewsError extends StatelessWidget {
  const _NewsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error.withValues(alpha: 0.8),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.newsLoadFailedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.actionRetry),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsLoadingList extends StatelessWidget {
  const _NewsLoadingList();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Skeleton(width: double.infinity, height: 180),
        SizedBox(height: 14),
        Skeleton(width: double.infinity, height: 90),
        SizedBox(height: 10),
        Skeleton(width: double.infinity, height: 90),
      ],
    );
  }
}

/// Header'ın en sağında duran bubble-shaped kategori reveal container.
/// Tıklanınca tüm kategorileri listeleyen bir bottom sheet açar; seçim
/// `onSelect` callback'i üzerinden parent'a iletilir. Önceden burada
/// görünen "Haberler" duplicate başlığı kaldırıldı — başlık artık
/// yalnızca flexibleSpace içindeki hero pill'de yaşıyor.
class _CategoryRevealBubble extends StatelessWidget {
  const _CategoryRevealBubble({
    required this.selected,
    required this.colorFor,
    required this.onSelect,
  });

  final NewsCategory? selected;
  final Color Function(NewsCategory) colorFor;
  final ValueChanged<NewsCategory?> onSelect;

  String _label(AppLocalizations l10n) {
    if (selected == null) return l10n.newsAllCategory;
    return '${selected!.emoji} ${selected!.localizedLabel(l10n)}';
  }

  Color _accent() => selected == null ? AppColors.accent : colorFor(selected!);

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<NewsCategory?>(
      context: context,
      // HomeShell'in floating tab bar'ı üstünde açılması için root
      // navigator'a bağlanıyor — aksi halde shell'in iç navigator'ı
      // içinde kalıp barın ALTINDA render ediliyordu (bkz. "Dünya"
      // butonunun barın altında kalması raporu).
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CategoryMenuSheet(
        selected: selected,
        colorFor: colorFor,
      ),
    );
    // sheet kapandığında `null` döndü; kullanıcı bir kategori
    // seçtiyse callback'i çağır. `null` seçimler "Tümü" demek.
    if (picked != null || (picked == null && selected != null)) {
      onSelect(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = _accent();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.85),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  _label(l10n),
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// _CategoryRevealBubble tarafından açılan bottom sheet: tüm
/// kategorileri emoji + label + renkli tile olarak listeler; "Tümü"
/// seçeneği en üstte durur. Seçim pill'in callback'ine geri döner.
class _CategoryMenuSheet extends StatelessWidget {
  const _CategoryMenuSheet({
    required this.selected,
    required this.colorFor,
  });

  final NewsCategory? selected;
  final Color Function(NewsCategory) colorFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                l10n.newsPickCategoryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            _sheetTile(
              context: context,
              emoji: '📰',
              label: l10n.newsAllCategory,
              color: AppColors.accent,
              isSelected: selected == null,
              onTap: () => Navigator.of(context).pop<NewsCategory?>(null),
            ),
            for (final c in NewsCategory.values)
              _sheetTile(
                context: context,
                emoji: c.emoji,
                label: c.localizedLabel(l10n),
                color: colorFor(c),
                isSelected: selected == c,
                onTap: () => Navigator.of(context).pop<NewsCategory?>(c),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile({
    required BuildContext context,
    required String emoji,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    softWrap: true,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFD9D2EC),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.check_rounded, color: color, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
