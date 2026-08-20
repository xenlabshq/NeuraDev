import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import 'news_form_page.dart';

/// Admin/moderatör için haber yönetim ekranı — ekle/düzenle/sil.
///
/// Erişim: bu sayfaya yalnızca `UserRole.isSupportStaff` (moderatör/admin)
/// kullanıcılar için gösterilen bir giriş noktasından (bkz. NewsPage FAB)
/// ulaşılır. Gerçek yetkilendirme burada değil, Firestore Security
/// Rules'ta (`firestore.rules`) sunucu tarafında zorunlu kılınır — bu
/// sayfa sadece uygun olmayan kullanıcıya bu ekranı hiç göstermemek için
/// bir istemci-tarafı kolaylık.
class NewsAdminPage extends ConsumerWidget {
  const NewsAdminPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    NewsArticle article,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haberi sil'),
        content: Text('"${article.title}" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(newsRepositoryProvider).deleteArticle(article.id);
    ref.invalidate(newsStreamProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNews = ref.watch(newsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Haber Yönetimi')),
      body: asyncNews.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('Henüz haber yok.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = articles[i];
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
                    '${a.source} · ${a.priority.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Düzenle',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NewsFormPage(existing: a),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _delete(context, ref, a),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Yeni haber ekle',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewsFormPage()),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
