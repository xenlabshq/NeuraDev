import 'package:equatable/equatable.dart';

/// Bir ders/node için öğrencinin "hafıza kartı".
/// Spaced repetition (aralıklı tekrar) algoritması tarafından kullanılır.
/// Kullanıcı her denemede bu kaydı günceller.
class NodeMemory extends Equatable {
  const NodeMemory({
    required this.nodeId,
    this.attempts = 0,
    this.successes = 0,
    this.mistakes = 0,
    this.consecutiveSuccesses = 0,
    this.confidence = 0.0,
    this.lastReview,
    this.nextReview,
    this.lastDifficulty = 0.5,
    this.averageTimeMs = 0,
  });

  /// Hangi node için.
  final String nodeId;

  /// Toplam deneme sayısı.
  final int attempts;

  /// Başarılı deneme sayısı (expectedOutput eşleşti).
  final int successes;

  /// Başarısız deneme sayısı.
  final int mistakes;

  /// Üst üste başarılı deneme sayısı (resetlenir hata olunca).
  final int consecutiveSuccesses;

  /// Güven skoru 0..1. 1 = tam öğrenildi, 0 = hiç denemedi.
  final double confidence;

  /// Son deneme zamanı.
  final DateTime? lastReview;

  /// Bir sonraki planlanmış tekrar zamanı.
  /// Şu andan önceyse "gösterilebilir" durumdadır.
  final DateTime? nextReview;

  /// Son denemenin zorluk değeri (0..1).
  /// Düşük = kolay hissettim, yüksek = çok zorlandım.
  final double lastDifficulty;

  /// Ortalama kod yazma süresi (ms). Hızlı yapabiliyorsa güven yüksek.
  final int averageTimeMs;

  /// Başarı oranı.
  double get successRate => attempts == 0 ? 0 : successes / attempts;

  /// Hata oranı.
  double get mistakeRate => attempts == 0 ? 0 : mistakes / attempts;

  /// Bu node "öğrenildi" mi?
  /// Koşullar: confidence >= 0.85, en az 3 başarılı deneme, ardışık hata yok.
  bool get isMastered =>
      confidence >= 0.85 &&
      consecutiveSuccesses >= 3 &&
      mistakeRate < 0.1 &&
      attempts >= 3;

  /// Bu node "zayıf" mı? — öğretmen daha fazla odaklanmalı.
  /// Koşullar: yüksek hata oranı veya düşük güven veya son denemede hata.
  bool get isWeak {
    if (attempts == 0) return true; // hiç denenmemiş = potansiyel zayıf
    if (confidence < 0.4) return true;
    if (mistakeRate > 0.5) return true;
    return false;
  }

  /// Şu anda gösterilebilir mi (nextReview zamanı geldi mi veya hiç denenmedi mi)?
  bool get isDue {
    if (nextReview == null) return true; // ilk kez
    return DateTime.now().isAfter(nextReview!);
  }

  /// Mastery level (0..3): 0 hiç, 1 başlangıç, 2 orta, 3 usta.
  int get masteryLevel {
    if (attempts == 0) return 0;
    if (confidence >= 0.85 && consecutiveSuccesses >= 3) return 3;
    if (confidence >= 0.6) return 2;
    return 1;
  }

  NodeMemory copyWith({
    int? attempts,
    int? successes,
    int? mistakes,
    int? consecutiveSuccesses,
    double? confidence,
    DateTime? lastReview,
    DateTime? nextReview,
    double? lastDifficulty,
    int? averageTimeMs,
  }) => NodeMemory(
    nodeId: nodeId,
    attempts: attempts ?? this.attempts,
    successes: successes ?? this.successes,
    mistakes: mistakes ?? this.mistakes,
    consecutiveSuccesses: consecutiveSuccesses ?? this.consecutiveSuccesses,
    confidence: confidence ?? this.confidence,
    lastReview: lastReview ?? this.lastReview,
    nextReview: nextReview ?? this.nextReview,
    lastDifficulty: lastDifficulty ?? this.lastDifficulty,
    averageTimeMs: averageTimeMs ?? this.averageTimeMs,
  );

  @override
  List<Object?> get props => [
    nodeId,
    attempts,
    successes,
    mistakes,
    consecutiveSuccesses,
    confidence,
    lastReview,
    nextReview,
    lastDifficulty,
    averageTimeMs,
  ];
}

/// Bir adanın tüm öğrenme istatistikleri.
class IslandMemoryStats extends Equatable {
  const IslandMemoryStats({
    required this.islandId,
    required this.memories,
  });

  final String islandId;
  final List<NodeMemory> memories;

  /// Ada ortalaması confidence (0..1).
  double get averageConfidence {
    if (memories.isEmpty) return 0;
    final sum = memories.fold<double>(0, (s, m) => s + m.confidence);
    return sum / memories.length;
  }

  /// Bu adada zayıf node sayısı.
  int get weakNodeCount => memories.where((m) => m.isWeak).length;

  /// Bu adada mastered node sayısı.
  int get masteredNodeCount => memories.where((m) => m.isMastered).length;

  /// Bu ada tamamen mastered mi?
  bool get isIslandMastered =>
      memories.isNotEmpty && masteredNodeCount == memories.length;

  /// Bu ada "kritik" mi? — birden fazla zayıf nokta var.
  bool get isCritical => weakNodeCount >= 2;

  @override
  List<Object?> get props => [islandId, memories];
}
