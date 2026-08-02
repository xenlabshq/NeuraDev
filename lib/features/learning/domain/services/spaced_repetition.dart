import 'dart:math' as math;

import '../entities/learning_memory.dart';

/// Basitleştirilmiş SuperMemo SM-2 adaptif öğrenme motoru.
///
/// SM-2'nin temel fikri:
/// - Her başarılı deneme sonrası "interval" (tekrar aralığı) büyür
/// - Hata durumunda interval sıfırlanır
/// - Confidence değeri başarı/hata oranına göre 0..1 arası ayarlanır
/// - "Ease factor" her başarı/hata ile güncellenir (1.3 altına düşerse zor)
class SpacedRepetition {
  SpacedRepetition._();

  /// Minimum interval (1 saat).
  static const Duration _minInterval = Duration(hours: 1);

  /// Maksimum interval (30 gün).
  static const Duration _maxInterval = Duration(days: 30);

  /// Başlangıç interval (1 gün).
  static const Duration _initialInterval = Duration(days: 1);

  /// Bir node için deneme sonucunu işle ve yeni memory kaydını döndür.
  ///
  /// [success]: doğru çıktı elde edildi mi?
  /// [mistakes]: kaç deneme yapıldı (kaç kez Çalıştır'a basıldı)
  /// [difficulty]: kullanıcının kendi zorluk algısı 0..1 (opsiyonel)
  /// [timeMs]: ilk denemeden son denemeye kadar geçen süre (ms)
  static NodeMemory recordAttempt(
    NodeMemory memory, {
    required bool success,
    int attemptsInSession = 1,
    double? difficulty,
    int timeMs = 0,
  }) {
    final now = DateTime.now();
    final newAttempts = memory.attempts + 1;
    final newSuccesses = success ? memory.successes + 1 : memory.successes;
    final newMistakes = success ? memory.mistakes : memory.mistakes + 1;
    final newConsecutive =
        success ? memory.consecutiveSuccesses + 1 : 0;

    // Confidence güncelleme: başarı oranı * ardışık başarı bonus * zorluk
    final baseRate = newSuccesses / newAttempts;
    final streakBonus = math.min(newConsecutive / 5.0, 1.0);
    final difficultyPenalty = difficulty != null
        ? (1.0 - difficulty * 0.3)
        : 1.0;
    final newConfidence =
        (baseRate * 0.6 + streakBonus * 0.3) * difficultyPenalty;
    final clampedConfidence = newConfidence.clamp(0.0, 1.0);

    // Sonraki tekrar aralığını hesapla
    Duration nextInterval;
    if (!success) {
      nextInterval = _minInterval;
    } else if (memory.attempts == 0) {
      nextInterval = _initialInterval;
    } else {
      // Önceki interval * ease factor
      final prevInterval = memory.nextReview != null
          ? memory.nextReview!.difference(memory.lastReview ?? now)
          : _initialInterval;
      // SM-2 ease: ardışık başarıya göre büyür, 1.3–2.5 arası
      final ease = 1.3 + (newConsecutive * 0.15);
      final newMinutes =
          (prevInterval.inMinutes * ease).clamp(60.0, double.infinity);
      nextInterval = Duration(minutes: newMinutes.toInt());
    }

    // Average time güncelle (running average)
    final newAvgTime = memory.attempts == 0
        ? timeMs
        : ((memory.averageTimeMs * memory.attempts) + timeMs) ~/ newAttempts;

    return memory.copyWith(
      attempts: newAttempts,
      successes: newSuccesses,
      mistakes: newMistakes,
      consecutiveSuccesses: newConsecutive,
      confidence: clampedConfidence,
      lastReview: now,
      nextReview: now.add(nextInterval),
      lastDifficulty: difficulty ?? memory.lastDifficulty,
      averageTimeMs: newAvgTime,
    );
  }

  /// Bir kullanıcı için önerilen sonraki node.
  /// - Hiç denenmemiş node'lar öncelikli
  /// - Zayıf node'lar (isWeak) öncelikli
  /// - Mastered node'lar düşük öncelikli
  /// - Süresi gelen node'lar (isDue) yüksek öncelikli
  static String? recommendNextNode(List<NodeMemory> memories) {
    if (memories.isEmpty) return null;

    final sorted = [...memories]..sort(_comparePriority);
    return sorted.first.nodeId;
  }

  /// Öncelik karşılaştırması — düşük skor = yüksek öncelik.
  /// Mantık:
  /// - Hiç denenmemiş (attempts == 0) → en yüksek
  /// - Süresi gelen ve zayıf → yüksek
  /// - Süresi gelen ve orta → orta
  /// - Mastered → en düşük
  static int _comparePriority(NodeMemory a, NodeMemory b) {
    final aScore = _priorityScore(a);
    final bScore = _priorityScore(b);
    return aScore.compareTo(bScore);
  }

  static double _priorityScore(NodeMemory m) {
    if (m.attempts == 0) return 0; // hiç denenmemiş = ilk öncelik
    if (m.isMastered) return 100; // öğrenilmiş = son öncelik

    double score = 50;
    if (m.isDue) score -= 20; // süresi geldiyse öne al
    if (m.isWeak) score -= 30; // zayıfsa daha öne al
    score -= m.confidence * 10; // düşük confidence = daha öne
    return score;
  }

  /// Tüm node'lardan "öğrenilmemiş" olanların listesini döndürür.
  /// Ada haritasında kırmızı kenarlık göstermek için kullanılır.
  static List<NodeMemory> weakNodes(List<NodeMemory> memories) {
    return memories.where((m) => m.isWeak).toList();
  }

  /// Bir node'un öğrenme eğrisini tahmin eder (UI progress bar için).
  /// 0..1 arası, 1 = mastered.
  static double learningProgress(NodeMemory memory) {
    if (memory.isMastered) return 1.0;
    if (memory.attempts == 0) return 0.0;
    // confidence * streak bonus
    final streakFactor = math.min(memory.consecutiveSuccesses / 5.0, 1.0);
    return (memory.confidence * 0.7 + streakFactor * 0.3).clamp(0.0, 1.0);
  }
}