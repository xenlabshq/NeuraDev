import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/seed_islands.dart';
import '../../domain/entities/learning_island.dart';

class UserLearningProgress extends Equatable {
  const UserLearningProgress({
    this.completedNodeIds = const {},
    this.totalXp = 0,
    this.streak = 0,
  });

  final Set<String> completedNodeIds;
  final int totalXp;
  final int streak;

  UserLearningProgress copyWith({
    Set<String>? completedNodeIds,
    int? totalXp,
    int? streak,
  }) => UserLearningProgress(
    completedNodeIds: completedNodeIds ?? this.completedNodeIds,
    totalXp: totalXp ?? this.totalXp,
    streak: streak ?? this.streak,
  );

  @override
  List<Object?> get props => [completedNodeIds, totalXp, streak];
}

/// Ada listesiyle birlikte progress-aware unlocked durumlarını da hesaplar.
class IslandsState extends Equatable {
  const IslandsState({
    required this.islands,
    required this.progress,
  });

  final List<LearningIsland> islands;
  final UserLearningProgress progress;

  IslandsState copyWith({
    List<LearningIsland>? islands,
    UserLearningProgress? progress,
  }) => IslandsState(
    islands: islands ?? this.islands,
    progress: progress ?? this.progress,
  );

  @override
  List<Object?> get props => [islands, progress];
}

class LearningProgressNotifier extends StateNotifier<IslandsState> {
  LearningProgressNotifier(this._cache)
    : super(_loadFromCache(_cache, IslandSeed.all()));

  final Box<dynamic> _cache;

  static const _kCompleted = 'completedNodeIds';
  static const _kTotalXp = 'totalXp';
  static const _kStreak = 'streak';

  static IslandsState _loadFromCache(
    Box<dynamic> box,
    List<LearningIsland> islands,
  ) {
    final completed = (box.get(_kCompleted) as List?)?.cast<String>().toSet();
    if (completed == null) {
      return IslandsState(
        islands: islands,
        progress: const UserLearningProgress(),
      );
    }
    return IslandsState(
      islands: islands,
      progress: UserLearningProgress(
        completedNodeIds: completed,
        totalXp: (box.get(_kTotalXp) as int?) ?? 0,
        streak: (box.get(_kStreak) as int?) ?? 0,
      ),
    );
  }

  void _saveToCache(UserLearningProgress progress) {
    _cache.put(_kCompleted, progress.completedNodeIds.toList());
    _cache.put(_kTotalXp, progress.totalXp);
    _cache.put(_kStreak, progress.streak);
  }

  /// Ada unlocked mi?
  bool isIslandUnlocked(int islandIndex) {
    if (islandIndex == 0) return true;
    final prev = state.islands[islandIndex - 1];
    return prev.nodes.every(
      (n) => state.progress.completedNodeIds.contains(n.id),
    );
  }

  /// Ada index'ini verilen id'ye göre bul.
  int islandIndexOf(String id) => state.islands.indexWhere((i) => i.id == id);

  /// Node unlocked mi?
  bool isNodeUnlocked(String islandId, int nodeIndex) {
    final island = state.islands.firstWhereOrNull((i) => i.id == islandId);
    if (island == null) return false;
    if (nodeIndex == 0) return true;
    final prevNodeId = island.nodes[nodeIndex - 1].id;
    return state.progress.completedNodeIds.contains(prevNodeId);
  }

  bool isNodeCompleted(String nodeId) =>
      state.progress.completedNodeIds.contains(nodeId);

  /// Node tamamlandı olarak işaretle, XP ve streak güncelle.
  /// F-09: tek adayı + bir sonraki komşunun unlocked'unu günceller;
  /// tüm ada listesini `copyWith` ile yeniden oluşturmaz.
  void markNodeCompleted(String nodeId, {required int xpEarned}) {
    if (state.progress.completedNodeIds.contains(nodeId)) return;
    final newCompleted = {...state.progress.completedNodeIds, nodeId};

    // Yeni ada listesi: hedef ada (kilit→kilit değil aynı kalır) +
    // bir sonraki komşunun unlocked bayrağı (öncekinin tamamlanması ile
    // otomatik açılır).
    final newIslands = _updateUnlockedForNode(
      state.islands,
      newCompleted,
      completedNodeId: nodeId,
    );

    final nextProgress = UserLearningProgress(
      completedNodeIds: newCompleted,
      totalXp: state.progress.totalXp + xpEarned,
      streak: state.progress.streak + 1,
    );
    state = IslandsState(islands: newIslands, progress: nextProgress);
    _saveToCache(nextProgress);
  }

  /// Tek bir node tamamlandığında etkilenen iki adayı (`prev`, `next`)
  /// immutable şekilde yeniden hesaplar; diğer ada instance'ları aynen
  /// korunur → referans eşitliği korunur, gereksiz rebuild tetiklenmez.
  static List<LearningIsland> _updateUnlockedForNode(
    List<LearningIsland> islands,
    Set<String> completed, {
    required String completedNodeId,
  }) {
    final updated = List<LearningIsland>.from(islands);
    for (var i = 0; i < updated.length; i++) {
      final island = updated[i];
      if (!island.nodes.any((n) => n.id == completedNodeId)) continue;
      // Önceki adanın tüm node'ları tamamlandıysa → bu ada unlock olabilir.
      if (i > 0) {
        final prev = updated[i - 1];
        final prevAllDone = prev.nodes.every((n) => completed.contains(n.id));
        if (prevAllDone && !prev.unlocked) {
          updated[i - 1] = prev.copyWith(unlocked: true);
        }
      }
      // Bir sonraki adanın tüm node'ları tamamlandıysa → o da unlock.
      if (i + 1 < updated.length) {
        final next = updated[i + 1];
        final nextAllDone = next.nodes.every((n) => completed.contains(n.id));
        if (nextAllDone && !next.unlocked) {
          updated[i + 1] = next.copyWith(unlocked: true);
        }
      }
      // Hedef ada zaten unlocked'tı; bir şey değiştirme (referans korunur).
      break;
    }
    return updated;
  }

  /// Streak sıfırlama (yanlış cevap).
  void resetStreak() {
    if (state.progress.streak == 0) return;
    final nextProgress = state.progress.copyWith(streak: 0);
    state = state.copyWith(progress: nextProgress);
    _saveToCache(nextProgress);
  }

  /// Tüm ilerlemeyi sıfırla (debug için).
  void resetProgress() {
    state = IslandsState(
      islands: IslandSeed.all(),
      progress: const UserLearningProgress(),
    );
    _cache.clear();
  }

  /// Ada unlocked + completed durumlarıyla birlikte node'ları döndürür.
  List<LearningNode> nodesWithState(LearningIsland island) {
    final completed = state.progress.completedNodeIds;
    final prevAllCompleted = island.nodes.every(
      (n) => completed.contains(n.id),
    );

    LearningNode completedNode(LearningNode n) => LearningNode.completed(
      id: n.id,
      title: n.title,
      description: n.description,
      tutorial: n.tutorial,
      starterCode: n.starterCode,
      solution: n.solution,
      expectedOutput: n.expectedOutput,
      points: n.points,
      emoji: n.emoji,
      order: n.order,
      bestScore: 100,
    );

    LearningNode lockedNode(LearningNode n) => LearningNode.locked(
      id: n.id,
      title: n.title,
      description: n.description,
      tutorial: n.tutorial,
      starterCode: n.starterCode,
      solution: n.solution,
      expectedOutput: n.expectedOutput,
      points: n.points,
      emoji: n.emoji,
      order: n.order,
    );

    LearningNode availableNode(LearningNode n) => LearningNode.available(
      id: n.id,
      title: n.title,
      description: n.description,
      tutorial: n.tutorial,
      starterCode: n.starterCode,
      solution: n.solution,
      expectedOutput: n.expectedOutput,
      points: n.points,
      emoji: n.emoji,
      order: n.order,
    );

    if (prevAllCompleted) {
      return island.nodes
          .map((n) => completed.contains(n.id) ? completedNode(n) : n)
          .toList();
    }

    return [
      for (var i = 0; i < island.nodes.length; i++)
        if (completed.contains(island.nodes[i].id))
          completedNode(island.nodes[i])
        else if (i == 0 || completed.contains(island.nodes[i - 1].id))
          availableNode(island.nodes[i])
        else
          lockedNode(island.nodes[i]),
    ];
  }
}

/// Progress provider — state'i IslandsState (adalar + progress içerir).
final learningProgressProvider =
    StateNotifierProvider<LearningProgressNotifier, IslandsState>(
      (ref) => LearningProgressNotifier(ref.watch(learningProgressBoxProvider)),
    );

/// Progress-only provider (XP, streak, completedNodeIds) — UI'da kolay erişim.
final userProgressProvider = Provider<UserLearningProgress>(
  (ref) => ref.watch(learningProgressProvider).progress,
);

/// Adalar provider — unlocked durumlarıyla reactive.
final islandsProvider = Provider<List<LearningIsland>>(
  (ref) {
    final state = ref.watch(learningProgressProvider);
    // Ref.computed: her progress değişiminde adalar yeniden hesaplanır.
    final result = <LearningIsland>[];
    final completed = state.progress.completedNodeIds;
    for (var i = 0; i < state.islands.length; i++) {
      final island = state.islands[i];
      final isUnlocked =
          i == 0 ||
          state.islands[i - 1].nodes.every((n) => completed.contains(n.id));
      result.add(island.copyWith(unlocked: isUnlocked));
    }
    return result;
  },
);
