import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/learning/presentation/providers/learning_providers.dart';
import 'package:neuroup/features/profile/presentation/badge_providers.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neuroup_hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('badge_providers_test_box');
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  // learningProgressProvider'ın gerçek kurulumu (Hive box) sadece
  // BadgeUnlockNotifier'ın _ref.listen çağrısının çökmemesi için var —
  // gerçek değerler her testte userProgressProvider override'ıyla verilir.
  ProviderContainer containerWithProgress(UserLearningProgress progress) {
    return ProviderContainer(
      overrides: [
        learningProgressBoxProvider.overrideWithValue(box),
        userProgressProvider.overrideWithValue(progress),
      ],
    );
  }

  group('BadgeUnlockNotifier', () {
    test('no unlocks with zero progress', () {
      final container = containerWithProgress(const UserLearningProgress());
      addTearDown(container.dispose);

      expect(container.read(badgeUnlockProvider).unlocks, isEmpty);
    });

    test('completing the first node unlocks only first_step', () {
      final container = containerWithProgress(
        const UserLearningProgress(completedNodeIds: {'n1'}),
      );
      addTearDown(container.dispose);

      expect(container.read(badgeUnlockProvider).unlocks.keys, {
        'first_step',
      });
    });

    test('5 completed nodes unlocks first_step, helper and quiz_master', () {
      final container = containerWithProgress(
        const UserLearningProgress(
          completedNodeIds: {'n1', 'n2', 'n3', 'n4', 'n5'},
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(badgeUnlockProvider).unlocks.keys, {
        'first_step',
        'helper',
        'quiz_master',
      });
    });

    test('a 7-day streak unlocks streak_7', () {
      final container = containerWithProgress(
        const UserLearningProgress(streak: 7),
      );
      addTearDown(container.dispose);

      expect(
        container.read(badgeUnlockProvider).unlocks.keys,
        contains('streak_7'),
      );
    });

    test('badgeIsUnlockedProvider reflects the unlock state', () {
      final container = containerWithProgress(
        const UserLearningProgress(completedNodeIds: {'n1'}),
      );
      addTearDown(container.dispose);

      expect(container.read(badgeIsUnlockedProvider('first_step')), isTrue);
      expect(container.read(badgeIsUnlockedProvider('streak_7')), isFalse);
    });

    test('unlockAll() marks every badge unlocked', () {
      final container = containerWithProgress(const UserLearningProgress());
      addTearDown(container.dispose);

      container.read(badgeUnlockProvider.notifier).unlockAll();

      expect(container.read(badgeUnlockProvider).unlocks.length, 8);
    });

    test('reset() clears all unlocks', () {
      final container = containerWithProgress(const UserLearningProgress());
      addTearDown(container.dispose);

      container.read(badgeUnlockProvider.notifier)
        ..unlockAll()
        ..reset();

      expect(container.read(badgeUnlockProvider).unlocks, isEmpty);
    });
  });
}
