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
  return ReelSubmissionRepositoryImpl(ref.watch(firestoreProvider));
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
  ReelsNotifier(ReelsRepository repo) : super(repo.getAll());

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
  /// (her stream event'inde tamamı) — bu yüzden id'si zaten state'te olan
  /// reels tekrar eklenmez, sadece yeni olanlar başa eklenir.
  void mergeSubmitted(List<GameReel> submitted) {
    final existingIds = state.map((r) => r.id).toSet();
    final newOnes = submitted.where((r) => !existingIds.contains(r.id));
    if (newOnes.isEmpty) return;
    state = [...newOnes, ...state];
  }
}

final reelProvider = Provider.family<GameReel?, String>((ref, id) {
  final reels = ref.watch(reelsProvider);
  for (final r in reels) {
    if (r.id == id) return r;
  }
  return null;
});
