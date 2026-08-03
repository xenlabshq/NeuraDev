import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neuroup/app/router/home_shell.dart';
import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/widgets/common_widgets.dart';
import 'package:neuroup/features/news/presentation/providers/news_providers.dart';

class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({required this.newsId, super.key});
  final String newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticle = ref.watch(newsArticleProvider(newsId));
    final tokens = AppColors.tokensOf(context);
    return Scaffold(
      body: asyncArticle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (article) {
          if (article == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Haber bulunamadı',
              message: 'Bu haber mevcut değil.',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.category.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 6),
                    GradientPill(
                      label: article.category.label,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (article.isBreaking)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.error, AppColors.orange],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'SON DAKİKA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.6,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        article.source,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text('•',
                          style: TextStyle(color: tokens.textTertiary)),
                      Text(
                        article.ageLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    article.summary,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    article.body,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  // Yüzen alt bar + safe area için boşluk bırak.
                  kBottomBarHeight + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Kaynakta Oku'),
                          onPressed: article.sourceUrl.isEmpty
                              ? null
                              : () => launchUrl(
                                    Uri.parse(article.sourceUrl),
                                    mode: LaunchMode.externalApplication,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Paylaş'),
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Paylaşım yakında'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
