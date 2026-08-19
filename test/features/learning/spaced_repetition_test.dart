import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/learning/domain/entities/learning_memory.dart';
import 'package:neuroup/features/learning/domain/services/spaced_repetition.dart';

void main() {
  group('SpacedRepetition.recordAttempt', () {
    test('first successful attempt schedules the initial 1-day interval', () {
      const memory = NodeMemory(nodeId: 'n1');
      final updated = SpacedRepetition.recordAttempt(memory, success: true);

      expect(updated.attempts, 1);
      expect(updated.successes, 1);
      expect(updated.consecutiveSuccesses, 1);
      final diff = updated.nextReview!.difference(updated.lastReview!);
      expect(diff, const Duration(days: 1));
    });

    test('a failure resets the consecutive-success streak and schedules '
        'the minimum interval', () {
      const memory = NodeMemory(
        nodeId: 'n1',
        attempts: 4,
        successes: 4,
        consecutiveSuccesses: 4,
        confidence: 0.9,
      );
      final updated = SpacedRepetition.recordAttempt(memory, success: false);

      expect(updated.consecutiveSuccesses, 0);
      expect(updated.mistakes, 1);
      final diff = updated.nextReview!.difference(updated.lastReview!);
      expect(diff, const Duration(hours: 1));
    });

    test('confidence increases toward 1.0 with repeated success', () {
      var memory = const NodeMemory(nodeId: 'n1');
      for (var i = 0; i < 6; i++) {
        memory = SpacedRepetition.recordAttempt(memory, success: true);
      }
      expect(memory.confidence, greaterThan(0.5));
      expect(memory.confidence, lessThanOrEqualTo(1.0));
    });

    test('the review interval never exceeds the 30-day cap', () {
      // Önceki interval'i yapay olarak çok büyük yapıyoruz (25 gün) ve
      // yüksek bir ease factor'e ulaşacak kadar ardışık başarı veriyoruz —
      // bu, cap uygulanmazsa 30 günü fazlasıyla aşan bir sonraki interval
      // üretir (25 gün * ~2.05 ease ≈ 51 gün).
      final lastReview = DateTime(2026, 1, 1);
      final priorNextReview = lastReview.add(const Duration(days: 25));
      final memory = NodeMemory(
        nodeId: 'n1',
        attempts: 5,
        successes: 5,
        consecutiveSuccesses: 5,
        confidence: 0.9,
        lastReview: lastReview,
        nextReview: priorNextReview,
      );

      final updated = SpacedRepetition.recordAttempt(memory, success: true);

      final diff = updated.nextReview!.difference(updated.lastReview!);
      expect(diff, const Duration(days: 30));
    });
  });

  group('SpacedRepetition.recommendNextNode', () {
    test('an unattempted node is recommended over an in-progress one', () {
      final memories = [
        const NodeMemory(nodeId: 'in_progress', attempts: 5, confidence: 0.9),
        const NodeMemory(nodeId: 'unseen'),
      ];
      expect(SpacedRepetition.recommendNextNode(memories), 'unseen');
    });

    test('a mastered node is deprioritized below a weak node', () {
      final memories = [
        const NodeMemory(
          nodeId: 'mastered',
          attempts: 5,
          successes: 5,
          consecutiveSuccesses: 5,
          confidence: 0.95,
        ),
        const NodeMemory(
          nodeId: 'weak',
          attempts: 3,
          successes: 1,
          mistakes: 2,
          confidence: 0.2,
        ),
      ];
      expect(SpacedRepetition.recommendNextNode(memories), 'weak');
    });

    test('returns null for an empty memory list', () {
      expect(SpacedRepetition.recommendNextNode(const []), isNull);
    });
  });

  group('SpacedRepetition.learningProgress', () {
    test('is 0 for an unattempted node', () {
      const memory = NodeMemory(nodeId: 'n1');
      expect(SpacedRepetition.learningProgress(memory), 0.0);
    });

    test('is 1 for a mastered node', () {
      const memory = NodeMemory(
        nodeId: 'n1',
        attempts: 5,
        successes: 5,
        consecutiveSuccesses: 5,
        confidence: 0.95,
      );
      expect(SpacedRepetition.learningProgress(memory), 1.0);
    });
  });
}
