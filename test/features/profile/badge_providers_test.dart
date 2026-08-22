import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/learning/presentation/providers/learning_providers.dart';
import 'package:neuroup/features/profile/presentation/badge_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neuroup_hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('badge_providers_test_box');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  // BadgeUnlockNotifier artık `learningProgressProvider`'ı (dolayısıyla
  // Hive box'ı) doğrudan okuyor — `userProgressProvider` üzerinden okumak
  // reactive listener içinde stale veri döndürebiliyordu (bkz. aşağıdaki
  // regresyon testi). Bu yüzden istenen progress'i `userProgressProvider`
  // override'ı yerine gerçek box'a yazıp `LearningProgressNotifier`'ın
  // kendi cache-yükleme mantığından geçiriyoruz.
  ProviderContainer containerWithProgress(UserLearningProgress progress) {
    box
      ..put('completedNodeIds', progress.completedNodeIds.toList())
      ..put('totalXp', progress.totalXp)
      ..put('streak', progress.streak);
    return ProviderContainer(
      overrides: [
        learningProgressBoxProvider.overrideWithValue(box),
        appSettingsProvider.overrideWith((ref) => AppSettingsNotifier(prefs)),
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

    test(
      'reacts to a real markNodeCompleted() call without overriding '
      'userProgressProvider (regression: badges never unlocked in the '
      'running app because the reactive listener read a stale '
      'userProgressProvider snapshot)',
      () {
        box
          ..put('completedNodeIds', <String>[])
          ..put('totalXp', 0)
          ..put('streak', 0);
        final container = ProviderContainer(
          overrides: [
            learningProgressBoxProvider.overrideWithValue(box),
            appSettingsProvider.overrideWith(
              (ref) => AppSettingsNotifier(prefs),
            ),
          ],
        );
        addTearDown(container.dispose);

        // ProfilePage döngüsünü taklit et: kullanıcı önce Profil'i (0
        // ilerlemeyle) açar — bu badgeUnlockProvider'ı ilk kez oluşturur.
        expect(container.read(badgeUnlockProvider).unlocks, isEmpty);

        // Sonra bir ders tamamlar (node_editor_page.dart'taki +XP akışı).
        container
            .read(learningProgressProvider.notifier)
            .markNodeCompleted('n1', xpEarned: 50);

        expect(
          container.read(badgeUnlockProvider).unlocks.keys,
          contains('first_step'),
        );
      },
    );
  });
}
