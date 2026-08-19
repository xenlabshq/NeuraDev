import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seed_islands.dart';
import '../../domain/entities/learning_island.dart';
import '../../domain/entities/learning_memory.dart';
import '../../domain/services/spaced_repetition.dart';

/// F-08: Ada listesini ve nodeId→islandId lookup map'i bir kez hesaplanır.
/// IslandSeed 10 ada × 5+ node içerdiğinden her build'de buraya 50+
/// firstWhere yapan kodu bu sabit map ile O(1)'e düşürüyoruz.
class _IslandIndex {
  static final _IslandIndex _instance = _IslandIndex._(
    islands: IslandSeed.all(),
    nodeToIsland: _buildNodeToIsland(IslandSeed.all()),
  );
  factory _IslandIndex() => _instance;

  _IslandIndex._({required this.islands, required this.nodeToIsland});

  final List<LearningIsland> islands;
  final Map<String, String> nodeToIsland;

  static Map<String, String> _buildNodeToIsland(List<LearningIsland> islands) {
    final map = <String, String>{};
    for (final island in islands) {
      for (final node in island.nodes) {
        map[node.id] = island.id;
      }
    }
    return map;
  }
}

/// Tüm node'ların hafıza kayıtları.
class AdaptiveMemoryState extends Equatable {
  const AdaptiveMemoryState({
    required this.records,
    required this.recommendations,
    required this.weakByIsland,
    required this.islandStatsMap,
  });

  /// nodeId → NodeMemory eşleştirmesi.
  final Map<String, NodeMemory> records;

  /// Ada başına önerilen sıradaki node ID'leri.
  final Map<String, String> recommendations;

  /// F-08: Ada başına zayıf noktalar — recordAttempt'ta pre-computed.
  final Map<String, List<NodeMemory>> weakByIsland;

  /// F-08: Ada başına istatistikler — recordAttempt'ta pre-computed.
  final Map<String, IslandMemoryStats> islandStatsMap;

  /// Belirli bir node için memory.
  NodeMemory? memoryFor(String nodeId) => records[nodeId];

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
    Map<String, List<NodeMemory>>? weakByIsland,
    Map<String, IslandMemoryStats>? islandStatsMap,
  }) =>
      AdaptiveMemoryState(
        records: records ?? this.records,
        recommendations: recommendations ?? this.recommendations,
        weakByIsland: weakByIsland ?? this.weakByIsland,
        islandStatsMap: islandStatsMap ?? this.islandStatsMap,
      );

  @override
  List<Object?> get props =>
      [records, recommendations, weakByIsland, islandStatsMap];
}

/// Adaptive memory notifier — spaced repetition motorunu yönetir.
class AdaptiveMemoryNotifier extends StateNotifier<AdaptiveMemoryState> {
  AdaptiveMemoryNotifier()
      : super(AdaptiveMemoryState(
          records: const {},
          recommendations: const {},
          weakByIsland: const {},
          islandStatsMap: const {},
        )) {
    // F-08: İlk açılışta tüm node'lar zayıf görünür (hiç denenmemiş =
    // potansiyel zayıf). Bu da pre-computed.
    _rebuildDerivedMaps(records: const {});
  }

  final _index = _IslandIndex();

  /// Bir node için ilk memory kaydı oluştur (hiç denenmemişse).
  void ensureRecord(String nodeId) {
    if (state.records.containsKey(nodeId)) return;
    final newRecords = {...state.records, nodeId: NodeMemory(nodeId: nodeId)};
    final derived = _rebuildDerivedMaps(records: newRecords);
    state = state.copyWith(
      records: newRecords,
      weakByIsland: derived.weak,
      islandStatsMap: derived.stats,
      recommendations: derived.recs,
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
    if (!state.records.containsKey(nodeId)) {
      ensureRecord(nodeId);
      // ensureRecord zaten state'i güncelledi — mevcut records'tan devam.
    }
    final current = state.records[nodeId]!;
    final updated = SpacedRepetition.recordAttempt(
      current,
      success: success,
      attemptsInSession: attemptsInSession,
      difficulty: difficulty,
      timeMs: timeMs,
    );
    final newRecords = {...state.records, nodeId: updated};
    final derived = _rebuildDerivedMaps(
      records: newRecords,
      targetIslandId: _index.nodeToIsland[nodeId],
    );
    state = state.copyWith(
      records: newRecords,
      weakByIsland: derived.weak,
      islandStatsMap: derived.stats,
      recommendations: derived.recs,
    );
    return updated;
  }

  /// F-08: weakByIsland + islandStatsMap + recommendations pre-compute.
  /// targetIslandId verildiğinde sadece o ada için incremental update yapar;
  /// null ise tüm adalar.
  ({Map<String, List<NodeMemory>> weak, Map<String, IslandMemoryStats> stats, Map<String, String> recs})
      _rebuildDerivedMaps({
    required Map<String, NodeMemory> records,
    String? targetIslandId,
  }) {
    final islands = _index.islands;

    // Mevcut map'leri kopyala; sadece hedef ada (veya tümü) yeniden hesaplanır.
    final weakByIsland =
        Map<String, List<NodeMemory>>.from(state.weakByIsland);
    final islandStatsMap =
        Map<String, IslandMemoryStats>.from(state.islandStatsMap);
    final recommendations =
        Map<String, String>.from(state.recommendations);

    final islandsToProcess = targetIslandId == null
        ? islands
        : islands.where((i) => i.id == targetIslandId);

    for (final island in islandsToProcess) {
      // Eğer ada'nın records'ta hiç memory yoksa, atla (graph boş = clean).
      final mems = island.nodes
          .map((n) => records[n.id])
          .whereType<NodeMemory>()
          .toList();
      if (mems.isEmpty) {
        islandStatsMap.remove(island.id);
        weakByIsland.remove(island.id);
        recommendations.remove(island.id);
        continue;
      }

      // Zayıf noktalar.
      final weak = mems.where((m) => m.isWeak).toList();
      if (weak.isEmpty) {
        weakByIsland.remove(island.id);
      } else {
        weakByIsland[island.id] = weak;
      }

      // İstatistikler.
      islandStatsMap[island.id] = IslandMemoryStats(
        islandId: island.id,
        memories: mems,
      );

      // Recommendation: sadece ada için.
      final nextId = SpacedRepetition.recommendNextNode(mems);
      if (nextId != null) {
        recommendations[island.id] = nextId;
      } else {
        recommendations.remove(island.id);
      }
    }

    return (
      weak: weakByIsland,
      stats: islandStatsMap,
      recs: recommendations,
    );
  }

  /// Bir ada için hangi node'a odaklanılması gerektiğini söyler.
  String? recommendedNodeFor(String islandId) =>
      state.recommendations[islandId];

  /// Bir adadaki zayıf node sayısı (UI badge için).
  int weakCountForIsland(String islandId) =>
      state.weakByIsland[islandId]?.length ?? 0;

  /// Tüm ilerlemeyi sıfırla (debug).
  void reset() {
    state = const AdaptiveMemoryState(
      records: {},
      recommendations: {},
      weakByIsland: {},
      islandStatsMap: {},
    );
  }
}

final adaptiveMemoryProvider =
    StateNotifierProvider<AdaptiveMemoryNotifier, AdaptiveMemoryState>(
  (ref) => AdaptiveMemoryNotifier(),
);

/// Bir ada için memory istatistikleri provider'ı.
/// F-08: doğrudan pre-computed map'ten okur, tek O(1) lookup.
final islandMemoryStatsProvider =
    Provider.family<IslandMemoryStats?, String>((ref, islandId) {
  return ref.watch(adaptiveMemoryProvider.select(
    (s) => s.islandStatsMap[islandId],
  ));
});

/// Bir node için memory provider'ı.
final nodeMemoryProvider =
    Provider.family<NodeMemory?, String>((ref, nodeId) {
  return ref.watch(adaptiveMemoryProvider.select(
    (s) => s.records[nodeId],
  ));
});

/// Tüm zayıf node'lar — ada haritası için.
/// F-08: pre-computed olduğundan O(records.length), eskiden
/// O(records × islands × nodes).
final weakNodesByIslandProvider =
    Provider<Map<String, List<NodeMemory>>>((ref) {
  return ref.watch(adaptiveMemoryProvider.select((s) => s.weakByIsland));
});

/// Bir ada için önerilen sonraki node ID.
final recommendedNodeProvider =
    Provider.family<String?, String>((ref, islandId) {
  return ref.watch(adaptiveMemoryProvider.select(
    (s) => s.recommendations[islandId],
  ));
});

/// LearningIsland re-export — provider'lar için kolay erişim.
typedef Island = LearningIsland;