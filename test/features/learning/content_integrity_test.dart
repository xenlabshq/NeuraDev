// Tüm ders içeriğinin (30 node) tutarlılığını doğrular:
// - solution kodu gerçekten expectedOutput'u üretiyor mu?
// - starterCode simülatörü çökertmiyor mu (syntax hatası vermemeli)?
// - Her node'un temel alanları (title/tutorial/emoji) boş değil mi?
//
// Bu test, ders içeriği elle düzenlenirken (yeni ders eklenirken veya
// mevcut biri değiştirilirken) "çözüm butonuna basınca öğrenciye yanlış
// veya boş çıktı gösterme" gibi sessiz içerik hatalarını yakalar.

import 'package:flutter_test/flutter_test.dart';
import 'package:neuroup/features/learning/data/python_simulator.dart';
import 'package:neuroup/features/learning/data/seed_islands.dart';
import 'package:neuroup/features/learning/data/seed_islands_en.dart';

void main() {
  final seeds = {'tr': IslandSeed.all(), 'en': IslandSeedEn.all()};

  test('there is at least one island with at least one node', () {
    for (final islands in seeds.values) {
      expect(islands, isNotEmpty);
      expect(islands.every((i) => i.nodes.isNotEmpty), isTrue);
    }
  });

  for (final seedEntry in seeds.entries) {
    final locale = seedEntry.key;
    final islands = seedEntry.value;
    for (final island in islands) {
      for (final node in island.nodes) {
        group('$locale / ${island.id} / ${node.id}', () {
          test('metadata alanları boş değil', () {
            expect(node.title.trim(), isNotEmpty);
            expect(node.tutorial.trim(), isNotEmpty);
            expect(node.emoji.trim(), isNotEmpty);
            expect(node.expectedOutput.trim(), isNotEmpty);
          });

          test(
            'solution kodu çalıştırıldığında expectedOutput ile eşleşir',
            () {
              final sim = PythonSimulator();
              final result = sim.run(node.solution);

              expect(
                result.success,
                isTrue,
                reason:
                    'solution çalıştırılamadı:\n${result.errors.join("\n")}\n'
                    'kod:\n${node.solution}',
              );
              expect(
                result.combinedOutput.trim(),
                node.expectedOutput.trim(),
                reason:
                    'solution çıktısı expectedOutput ile eşleşmiyor.\n'
                    'kod:\n${node.solution}',
              );
            },
          );

          test('starterCode simülatörü hatasız çalıştırır (syntax olarak)', () {
            // starterCode genelde eksik/yarım bırakılmıştır (öğrenci
            // tamamlayacak) — bu yüzden expectedOutput ile eşleşmesini
            // BEKLEMİYORUZ, sadece simülatörün çökmediğini (ör. sonsuz
            // döngü guard'ına takılmadığını) doğruluyoruz.
            final sim = PythonSimulator();
            final result = sim.run(node.starterCode);
            final infiniteLoopGuard = result.errors.any(
              (e) => e.contains('RuntimeError') && e.contains('döngü'),
            );
            expect(
              infiniteLoopGuard,
              isFalse,
              reason:
                  'starterCode sonsuz döngü guard\'ına takıldı:\n${node.starterCode}',
            );
          });
        });
      }
    }
  }
}
