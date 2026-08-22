import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/home_shell.dart' show LessonOverlayScope;
import '../../../../app/theme/colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import '../utils/news_labels.dart';
import 'news_form_page.dart';

/// Admin/moderatör için haber yönetim ekranı — ekle/düzenle/sil.
///
/// Gerçek bir haber sitesinin yönetim paneli gibi çalışır: kategoriye
/// göre filtrelenebilir, geçmiş haberler "Daha Fazla Yükle" ile
/// sayfalanarak gezilebilir (tek seferde 100 haberle sınırlı değil),
/// ve her haber düzenlenebilir/silinebilir.
///
/// Erişim: bu sayfaya yalnızca `UserRole.isSupportStaff` (moderatör/admin)
/// kullanıcılar için gösterilen bir giriş noktasından (bkz. NewsPage FAB)
/// ulaşılır. Gerçek yetkilendirme burada değil, Firestore Security
/// Rules'ta (`firestore.rules`) sunucu tarafında zorunlu kılınır — bu
/// sayfa sadece uygun olmayan kullanıcıya bu ekranı hiç göstermemek için
/// bir istemci-tarafı kolaylık.
class NewsAdminPage extends ConsumerStatefulWidget {
  const NewsAdminPage({super.key});

  @override
  ConsumerState<NewsAdminPage> createState() => _NewsAdminPageState();
}

class _NewsAdminPageState extends ConsumerState<NewsAdminPage> {
  LessonOverlayScope? _overlayScope;

  @override
  void initState() {
    super.initState();
    // Shell altındaki floating tab bar'ı gizle — aksi halde FAB ve
    // "Daha Fazla Yükle" düğmesi barın altında kalıyordu.
    _overlayScope = LessonOverlayScope(context);
  }

  @override
  void dispose() {
    _overlayScope?.dispose();
    super.dispose();
  }

  Future<void> _delete(NewsArticle article) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteNewsTitle),
        content: Text(l10n.adminDeleteNewsConfirm(article.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionGiveUp),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(newsRepositoryProvider).deleteArticle(article.id);
    if (!mounted) return;
    ref.invalidate(newsStreamProvider);
    await ref.read(newsAdminArchiveProvider.notifier).reload();
  }

  Future<void> _openForm({NewsArticle? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NewsFormPage(existing: existing)),
    );
    if (!mounted) return;
    ref.invalidate(newsStreamProvider);
    await ref.read(newsAdminArchiveProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final archive = ref.watch(newsAdminArchiveProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminNewsManagementTitle)),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: [
                _AdminCategoryChip(
                  label: l10n.newsAllCategory,
                  selected: archive.category == null,
                  onTap: () => ref
                      .read(newsAdminArchiveProvider.notifier)
                      .setCategory(null),
                ),
                const SizedBox(width: 8),
                for (final c in NewsCategory.values) ...[
                  _AdminCategoryChip(
                    label: '${c.emoji} ${c.localizedLabel(l10n)}',
                    selected: archive.category == c,
                    onTap: () => ref
                        .read(newsAdminArchiveProvider.notifier)
                        .setCategory(c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: archive.articles.isEmpty && archive.loading
                ? const Center(child: CircularProgressIndicator())
                : archive.articles.isEmpty
                ? Center(child: Text(l10n.adminNoNewsYet))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: archive.articles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == archive.articles.length) {
                        return _ArchiveFooter(
                          hasMore: archive.hasMore,
                          loading: archive.loading,
                          onLoadMore: () => ref
                              .read(newsAdminArchiveProvider.notifier)
                              .loadMore(),
                        );
                      }
                      final a = archive.articles[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Text(
                            a.category.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(
                            a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${a.source} · ${a.priority.localizedLabel(l10n)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.actionEdit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(existing: a),
                              ),
                              IconButton(
                                tooltip: l10n.actionDelete,
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _delete(a),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: l10n.adminAddNewsTooltip,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _AdminCategoryChip extends StatelessWidget {
  const _AdminCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// Liste sonu — daha fazla haber varsa "Daha Fazla Yükle" butonu,
/// yükleniyorsa spinner, arşiv tükendiyse hiçbir şey göstermez.
class _ArchiveFooter extends StatelessWidget {
  const _ArchiveFooter({
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
  });
  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: onLoadMore,
                child: Text(l10n.adminLoadMoreArchive),
              ),
      ),
    );
  }
}
