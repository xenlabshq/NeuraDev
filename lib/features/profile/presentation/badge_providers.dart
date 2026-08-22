import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/presentation/providers/learning_providers.dart';
import '../../../shared/models/user_level.dart';

/// Tek bir rozet için unlock state'i.
class BadgeUnlock extends Equatable {
  const BadgeUnlock({
    required this.badgeId,
    required this.unlockedAt,
  });

  final String badgeId;
  final DateTime unlockedAt;

  @override
  List<Object?> get props => [badgeId, unlockedAt];
}

/// Rozet unlock koleksiyonu.
class BadgeState extends Equatable {
  const BadgeState({this.unlocks = const {}});

  /// badgeId → unlock zamanı.
  final Map<String, DateTime> unlocks;

  bool isUnlocked(String id) => unlocks.containsKey(id);

  BadgeState copyWith({Map<String, DateTime>? unlocks}) =>
      BadgeState(unlocks: unlocks ?? this.unlocks);

  @override
  List<Object?> get props => [unlocks];
}

/// Rozet unlock motoru.
/// Learning progress'i izler, koşullar sağlandığında otomatik olarak
/// rozet unlock'lar. State sadece debug/seed değil, gerçek davranış.
class BadgeUnlockNotifier extends StateNotifier<BadgeState> {
  BadgeUnlockNotifier(this._ref) : super(const BadgeState()) {
    // İlk oluşturulduğunda mevcut progress'i değerlendir.
    _evaluate(_ref.read(learningProgressProvider).progress);
    // İleride değişim olursa tetikle. `next.progress`'i doğrudan callback
    // parametresinden alıyoruz — `_ref.read(userProgressProvider)` gibi
    // TÜRETİLMİŞ bir provider'ı bu callback içinde okumak eski/stale
    // değer döndürebiliyordu (Riverpod, `learningProgressProvider`'ın
    // doğrudan dinleyicilerini, ondan türeyen `userProgressProvider`'ın
    // henüz yeniden hesaplanmamış olabileceği bir sırada tetikleyebiliyor).
    // Bu yüzden rozetler hiç açılmıyordu.
    _ref.listen<IslandsState>(
      learningProgressProvider,
      (_, next) => _evaluate(next.progress),
    );
  }

  final Ref _ref;

  /// Tüm rozetleri verilen progress'e göre değerlendir;
  /// koşul sağlandıysa unlock'la.
  void _evaluate(UserLearningProgress progress) {
    final newUnlocks = <String, DateTime>{};
    final existing = state.unlocks;

    for (final template in Badges.all) {
      // Zaten unlocked ise koru.
      if (existing.containsKey(template.id)) {
        newUnlocks[template.id] = existing[template.id]!;
        continue;
      }
      // Koşulu sağlıyorsa unlock.
      if (_checkCondition(template.id, progress)) {
        newUnlocks[template.id] = DateTime.now();
      }
    }

    if (newUnlocks.length != existing.length ||
        !newUnlocks.keys.every(existing.containsKey)) {
      state = state.copyWith(unlocks: newUnlocks);
    }
  }

  /// Rozet koşulunu değerlendir. Basit ama genişletilebilir kurallar.
  bool _checkCondition(String id, UserLearningProgress progress) {
    switch (id) {
      case 'first_step':
        // İlk node tamamlandı.
        return progress.completedNodeIds.isNotEmpty;
      case 'streak_7':
        // 7 ardışık başarı.
        return progress.streak >= 7;
      case 'helper':
        // 5+ node tamamlamış olmak (yardımseverlik seviyesi).
        return progress.completedNodeIds.length >= 5;
      case 'math_wizard':
        // Tüm matematik node'larını tamamla — şimdilik 10+ node.
        return progress.completedNodeIds.length >= 10;
      case 'science_explorer':
        // 15+ node (fen bloğu).
        return progress.completedNodeIds.length >= 15;
      case 'history_buff':
        // 20+ node (tarih bloğu).
        return progress.completedNodeIds.length >= 20;
      case 'quiz_master':
        // 5+ tamamlama.
        return progress.completedNodeIds.length >= 5;
      case 'word_champion':
        // 25+ node.
        return progress.completedNodeIds.length >= 25;
      default:
        return false;
    }
  }

  /// Test için: tüm rozetleri unlock et.
  void unlockAll() {
    final now = DateTime.now();
    final map = <String, DateTime>{};
    for (var i = 0; i < Badges.all.length; i++) {
      map[Badges.all[i].id] = now.subtract(
        Duration(days: Badges.all.length - i),
      );
    }
    state = state.copyWith(unlocks: map);
  }

  /// Tüm ilerlemeyi sıfırla.
  void reset() {
    state = const BadgeState();
  }
}

final badgeUnlockProvider =
    StateNotifierProvider<BadgeUnlockNotifier, BadgeState>(
      (ref) => BadgeUnlockNotifier(ref),
    );

/// Tek bir rozet için unlock durumu.
final badgeIsUnlockedProvider = Provider.family<bool, String>((ref, badgeId) {
  return ref.watch(
    badgeUnlockProvider.select((s) => s.unlocks.containsKey(badgeId)),
  );
});

/// Tüm unlock zamanları (read-only).
final badgeUnlocksProvider = Provider<Map<String, DateTime>>((ref) {
  return ref.watch(badgeUnlockProvider.select((s) => s.unlocks));
});
