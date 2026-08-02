import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seed_islands.dart';
import '../../domain/entities/learning_island.dart';
import '../../domain/entities/learning_memory.dart';
import '../../domain/services/spaced_repetition.dart';

/// Tüm node'ların hafıza kayıtları.
class AdaptiveMemoryState extends Equatable {
  const AdaptiveMemoryState({
    required this.records,
    required this.recommendations,
  });

  /// nodeId → NodeMemory eşleştirmesi.
  final Map<String, NodeMemory> records;

  /// Ada başına önerilen sıradaki node ID'leri.
  final Map<String, String> recommendations;

  /// Belirli bir node için memory.
  NodeMemory? memoryFor(String nodeId) => records[nodeId];

  /// Tüm zayıf node'ları ada bazlı gruplanmış döndürür.
  /// Ada haritasında kırmızı kenarlık göstermek için.
  Map<String, List<NodeMemory>> weakNodesByIsland() {
    final map = <String, List<NodeMemory>>{};
    for (final mem in records.values) {
      if (!mem.isWeak) continue;
      // Hangi ada ait olduğunu bul
      final island = IslandSeed.all().firstWhere(
        (i) => i.nodes.any((n) => n.id == mem.nodeId),
        orElse: () => IslandSeed.all().first,
      );
      map.putIfAbsent(island.id, () => []).add(mem);
    }
    return map;
  }

  /// Ada bazlı istatistikler.
  Map<String, IslandMemoryStats> islandStats() {
    final islands = IslandSeed.all();
    final map = <String, IslandMemoryStats>{};
    for (final island in islands) {
      final mems = island.nodes
          .map((n) => records[n.id])
          .whereType<NodeMemory>()
          .toList();
      map[island.id] = IslandMemoryStats(
        islandId: island.id,
        memories: mems,
      );
    }
    return map;
  }

  /// Tüm node'lar mastered mi? (tüm eğitim bitti mi?)
  bool get allMastered =>
      records.isNotEmpty && records.values.every((m) => m.isMastered);

  /// Genel ortalama güven skoru.
  double get averageConfidence {
    if (records.isEmpty) return 0;
    final sum = records.values.fold<double>(0, (s, m) => s + m.confidence);
    return sum / records.length;
  }

  AdaptiveMemoryState copyWith({
    Map<String, NodeMemory>? records,
    Map<String, String>? recommendations,
  }) =>
      AdaptiveMemoryState(
        records: records ?? this.records,
        recommendations: recommendations ?? this.recommendations,
      );

  @override
  List<Object?> get props => [records, recommendations];
}

/// Adaptive memory notifier — spaced repetition motorunu yönetir.
class AdaptiveMemoryNotifier extends StateNotifier<AdaptiveMemoryState> {
  AdaptiveMemoryNotifier()
      : super(AdaptiveMemoryState(
          records: const {},
          recommendations: const {},
        ));

  /// Bir node için ilk memory kaydı oluştur (hiç denenmemişse).
  void ensureRecord(String nodeId) {
    if (state.records.containsKey(nodeId)) return;
    state = state.copyWith(
      records: {...state.records, nodeId: NodeMemory(nodeId: nodeId)},
    );
  }

  /// Bir node için deneme sonucunu işle ve yeni memory kaydını döndür.
  NodeMemory recordAttempt(
    String nodeId, {
    required bool success,
    int attemptsInSession = 1,
    double? difficulty,
    int timeMs = 0,
  }) {
    ensureRecord(nodeId);
    final current = state.records[nodeId]!;
    final updated = SpacedRepetition.recordAttempt(
      current,
      success: success,
      attemptsInSession: attemptsInSession,
      difficulty: difficulty,
      timeMs: timeMs,
    );
    state = state.copyWith(
      records: {...state.records, nodeId: updated},
      recommendations: _recomputeRecommendations(),
    );
    return updated;
  }

  /// Ada bazlı "sonraki önerilen node" hesapla.
  /// Hiç denenmemiş → önce. Zayıf + due → sonra. Mastered → son.
  Map<String, String> _recomputeRecommendations() {
    final islands = IslandSeed.all();
    final map = <String, String>{};
    for (final island in islands) {
      final mems = island.nodes
          .map((n) => state.records[n.id])
          .whereType<NodeMemory>()
          .toList();
      if (mems.isEmpty) continue;
      final nextId = SpacedRepetition.recommendNextNode(mems);
      if (nextId != null) {
        map[island.id] = nextId;
      }
    }
    return map;
  }

  /// Bir ada için hangi node'a odaklanılması gerektiğini söyler.
  String? recommendedNodeFor(String islandId) =>
      state.recommendations[islandId];

  /// Bir adadaki zayıf node sayısı (UI badge için).
  int weakCountForIsland(String islandId) {
    final island = IslandSeed.all().firstWhere((i) => i.id == islandId);
    final mems = island.nodes
        .map((n) => state.records[n.id])
        .whereType<NodeMemory>()
        .toList();
    return mems.where((m) => m.isWeak).length;
  }

  /// Tüm ilerlemeyi sıfırla (debug).
  void reset() {
    state = const AdaptiveMemoryState(
      records: {},
      recommendations: {},
    );
  }
}

final adaptiveMemoryProvider =
    StateNotifierProvider<AdaptiveMemoryNotifier, AdaptiveMemoryState>(
  (ref) => AdaptiveMemoryNotifier(),
);

/// Bir ada için memory istatistikleri provider'ı.
final islandMemoryStatsProvider =
    Provider.family<IslandMemoryStats?, String>((ref, islandId) {
  final state = ref.watch(adaptiveMemoryProvider);
  return state.islandStats()[islandId];
});

/// Bir node için memory provider'ı.
final nodeMemoryProvider =
    Provider.family<NodeMemory?, String>((ref, nodeId) {
  final state = ref.watch(adaptiveMemoryProvider);
  return state.memoryFor(nodeId);
});

/// Tüm zayıf node'lar — ada haritası için.
final weakNodesByIslandProvider =
    Provider<Map<String, List<NodeMemory>>>((ref) {
  final state = ref.watch(adaptiveMemoryProvider);
  return state.weakNodesByIsland();
});

/// Bir ada için önerilen sonraki node ID.
final recommendedNodeProvider =
    Provider.family<String?, String>((ref, islandId) {
  final state = ref.watch(adaptiveMemoryProvider);
  return state.recommendations[islandId];
});

/// LearningIsland re-export — provider'lar için kolay erişim.
typedef Island = LearningIsland;