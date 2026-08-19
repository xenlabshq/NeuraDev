import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/learning/presentation/pages/node_editor_page.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'neuroup_node_editor_hive',
    );
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('node_editor_test_box');
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  Widget wrap() => ProviderScope(
    overrides: [learningProgressBoxProvider.overrideWithValue(box)],
    child: const MaterialApp(
      // island_variables / n_var_2: 'sayi = 42\nondalik = 3.14\n
      // print(sayi)\nprint(ondalik)' — gerçek seed içeriği.
      home: NodeEditorPage(islandId: 'island_variables', nodeId: 'n_var_2'),
    ),
  );

  testWidgets(
    'running code shows the variable tracker with the final step',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.tap(find.text('Çalıştır'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('DEĞİŞKEN İZLEYİCİ'), findsOneWidget);
      // 4 satır (2 atama + 2 print) → son adım "Adım 4/4".
      expect(find.text('Adım 4/4'), findsOneWidget);
      // find.text (exact) sadece izleyicinin kendi Text widget'larına
      // eşleşir — kod editöründeki EditableText tüm kodu tek blok
      // olarak tuttuğu için "sayi"/"ondalik" ile birebir eşleşmez.
      expect(find.text('sayi'), findsOneWidget);
      expect(find.text('ondalik'), findsOneWidget);
    },
  );

  testWidgets('stepping back shows an earlier variable snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Çalıştır'));
    await tester.pump(const Duration(milliseconds: 350));

    // Geri git: adım 4 -> adım 1 (sadece 'sayi' tanımlı, 'ondalik' yok).
    await tester.tap(find.byTooltip('Önceki adım'));
    await tester.tap(find.byTooltip('Önceki adım'));
    await tester.tap(find.byTooltip('Önceki adım'));
    await tester.pump();

    expect(find.text('Adım 1/4'), findsOneWidget);
    expect(find.text('sayi'), findsOneWidget);
    expect(find.text('ondalik'), findsNothing);
  });
}
