import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) =>
      UserLearningProgress(
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
  }) =>
      IslandsState(
        islands: islands ?? this.islands,
        progress: progress ?? this.progress,
      );

  @override
  List<Object?> get props => [islands, progress];
}

class LearningProgressNotifier extends StateNotifier<IslandsState> {
  LearningProgressNotifier()
      : super(IslandsState(
          islands: IslandSeed.all(),
          progress: const UserLearningProgress(),
        ));

  /// Gerçek unlocked durumlarıyla güncellenmiş ada listesi.
  /// İlk ada her zaman açık. Sonraki adalar, bir önceki tüm
  /// node'ları tamamlandıysa açılır.
  List<LearningIsland> get _unlockedIslands {
    final completed = state.progress.completedNodeIds;
    final result = <LearningIsland>[];
    for (var i = 0; i < state.islands.length; i++) {
      final island = state.islands[i];
      final isUnlocked = i == 0 ||
          state.islands[i - 1]
              .nodes
              .every((n) => completed.contains(n.id));
      result.add(island.copyWith(unlocked: isUnlocked));
    }
    return result;
  }

  /// Ada unlocked mi?
  bool isIslandUnlocked(int islandIndex) {
    if (islandIndex == 0) return true;
    final prev = state.islands[islandIndex - 1];
    return prev.nodes
        .every((n) => state.progress.completedNodeIds.contains(n.id));
  }

  /// Ada index'ini verilen id'ye göre bul.
  int islandIndexOf(String id) =>
      state.islands.indexWhere((i) => i.id == id);

  /// Node unlocked mi?
  bool isNodeUnlocked(String islandId, int nodeIndex) {
    final island = state.islands.firstWhere((i) => i.id == islandId);
    if (nodeIndex == 0) return true;
    final prevNodeId = island.nodes[nodeIndex - 1].id;
    return state.progress.completedNodeIds.contains(prevNodeId);
  }

  bool isNodeCompleted(String nodeId) =>
      state.progress.completedNodeIds.contains(nodeId);

  /// Node tamamlandı olarak işaretle, XP ve streak güncelle.
  /// Bir sonraki ada otomatik açılır (island list otomatik güncellenir).
  void markNodeCompleted(String nodeId, {required int xpEarned}) {
    if (state.progress.completedNodeIds.contains(nodeId)) return;
    final newCompleted = {...state.progress.completedNodeIds, nodeId};
    state = state.copyWith(
      progress: state.progress.copyWith(
        completedNodeIds: newCompleted,
        totalXp: state.progress.totalXp + xpEarned,
        streak: state.progress.streak + 1,
      ),
    );
  }

  /// Streak sıfırlama (yanlış cevap).
  void resetStreak() {
    if (state.progress.streak == 0) return;
    state = state.copyWith(
      progress: state.progress.copyWith(streak: 0),
    );
  }

  /// Sadece progress'i değiştir, adaları yeniden hesapla.
  void _recomputeIslands() {
    state = state.copyWith(
      islands: List<LearningIsland>.from(_unlockedIslands),
    );
  }

  /// Tüm ilerlemeyi sıfırla (debug için).
  void resetProgress() {
    state = IslandsState(
      islands: IslandSeed.all(),
      progress: const UserLearningProgress(),
    );
  }

  /// Ada unlocked + completed durumlarıyla birlikte node'ları döndürür.
  List<LearningNode> nodesWithState(LearningIsland island) {
    final completed = state.progress.completedNodeIds;
    final prevAllCompleted = island.nodes.every((n) => completed.contains(n.id));

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
          lockedNode(island.nodes[i])
    ];
  }
}

/// Progress provider — state'i IslandsState (adalar + progress içerir).
final learningProgressProvider =
    StateNotifierProvider<LearningProgressNotifier, IslandsState>(
  (ref) => LearningProgressNotifier(),
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
      final isUnlocked = i == 0 ||
          state.islands[i - 1].nodes.every((n) => completed.contains(n.id));
      result.add(island.copyWith(unlocked: isUnlocked));
    }
    return result;
  },
);
