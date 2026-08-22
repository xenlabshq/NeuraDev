import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env/env.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/game_reel.dart';
import '../../domain/repositories/reel_submission_repository.dart';
import '../../domain/repositories/reels_repository.dart';
import '../../data/in_memory_reel_submission_repository.dart';
import '../../data/in_memory_reels_repository.dart';
import '../../data/reel_submission_repository_impl.dart';

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => InMemoryReelsRepository(),
);

final reelSubmissionRepositoryProvider = Provider<ReelSubmissionRepository>((
  ref,
) {
  if (!Env.firebaseConfigured) {
    return InMemoryReelSubmissionRepository();
  }
  return ReelSubmissionRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final reelsProvider = StateNotifierProvider<ReelsNotifier, List<GameReel>>((
  ref,
) {
  final notifier = ReelsNotifier(ref.read(reelsRepositoryProvider));
  final sub = ref
      .watch(reelSubmissionRepositoryProvider)
      .watchSubmittedReels()
      .listen(notifier.mergeSubmitted);
  ref.onDispose(sub.cancel);
  return notifier;
});

/// Reels akışının durumunu yönetir. Beğeni/kaydet/takip/yorum tamamen
/// istemci tarafında, oturum-içi (seed verisi gerçek bir backend'e bağlı
/// olmadığı için bunlar kalıcı değildir). Kullanıcı gönderimleri ise
/// [ReelSubmissionRepository] üzerinden kalıcı olarak eklenir ve
/// [mergeSubmitted] ile mevcut listeye katılır.
class ReelsNotifier extends StateNotifier<List<GameReel>> {
  ReelsNotifier(this._repo) : super(_repo.getAll()) {
    _seedLoaded = state.length;
  }

  final ReelsRepository _repo;
  late int _seedLoaded;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  /// Sonsuz kaydırma — kullanıcı akışın sonuna yaklaştığında çağrılır.
  /// Şu an sabit seed veri üzerinde çalıştığı için bir noktadan sonra
  /// [_hasMore] false olur, ama mimari gerçek bir backend'den gelecek
  /// büyüyen bir arşivi de aynı şekilde destekler.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final more = await _repo.fetchMore(offset: _seedLoaded);
      _seedLoaded += more.length;
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      final existingIds = state.map((r) => r.id).toSet();
      final newOnes = more.where((r) => !existingIds.contains(r.id));
      if (newOnes.isNotEmpty) {
        state = [...state, ...newOnes];
      }
    } finally {
      _loadingMore = false;
    }
  }

  void toggleLike(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          r.copyWith(liked: !r.liked, likes: r.likes + (!r.liked ? 1 : -1))
        else
          r,
    ];
  }

  void toggleSave(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(saved: !r.saved) else r,
    ];
  }

  void toggleFollow(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(following: !r.following) else r,
    ];
  }

  void addComment(String reelId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = [
      for (final r in state)
        if (r.id == reelId)
          r.copyWith(
            comments: [
              ReelComment(user: '@sen', text: trimmed, isMe: true),
              ...r.comments,
            ],
          )
        else
          r,
    ];
  }

  /// [submitted], gönderim repository'sindeki GÜNCEL tam listeyi taşır
  /// (her stream event'inde tamamı). Yeni id'ler başa eklenir; artık
  /// akışta olmayan (silinmiş) gönderiler state'ten çıkarılır; içeriği
  /// değişen (düzenlenen) gönderiler güncellenir ama yerel
  /// beğeni/kaydet/takip/yorum durumu korunur (bunlar sunucuda tutulmaz).
  /// Seed (demo) reels'e (`uploaderId == null`) hiç dokunulmaz.
  void mergeSubmitted(List<GameReel> submitted) {
    final submittedById = {for (final r in submitted) r.id: r};
    final kept = <GameReel>[];
    final seenIds = <String>{};

    for (final r in state) {
      if (r.uploaderId == null) {
        kept.add(r);
        continue;
      }
      final fresh = submittedById[r.id];
      if (fresh == null) continue; // silindi — listeden düş
      seenIds.add(r.id);
      kept.add(
        fresh.copyWith(
          liked: r.liked,
          saved: r.saved,
          following: r.following,
          comments: r.comments,
        ),
      );
    }

    final newOnes = submitted.where((r) => !seenIds.contains(r.id));
    state = [...newOnes, ...kept];
  }

  /// Bir gönderi silindiğinde anında (stream round-trip'i beklemeden)
  /// yerelden kaldırır — `mergeSubmitted` zaten aynı sonuca varır ama
  /// bu, silme sonrası UI'ın gecikmesiz güncellenmesini sağlar.
  void removeReel(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final reelProvider = Provider.family<GameReel?, String>((ref, id) {
  final reels = ref.watch(reelsProvider);
  for (final r in reels) {
    if (r.id == id) return r;
  }
  return null;
});
