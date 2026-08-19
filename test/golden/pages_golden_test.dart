// Golden (UI regresyon) testleri — birkaç kritik sayfanın render çıktısını
// referans PNG'lerle karşılaştırır. İstemsiz görsel değişiklikleri yakalar.
//
// Referansları yeniden üretmek için:
//   flutter test --update-goldens test/golden/
//
// Not: Goldens bu makinede (Flutter 3.44.8, Linux) üretildi. CI da aynı
// Flutter sürümünü Linux üzerinde kullanıyor (.github/workflows/ci.yml),
// bu yüzden font render farkı beklenmiyor — yine de farklı bir platformda
// (macOS/Windows) çalıştırılırsa küçük piksel farkları görülebilir.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neuroup/app/pages/demo_landing_page.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/profile/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _kGoldenSize = Size(393, 1400);

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: _kGoldenSize,
          devicePixelRatio: 1.0,
        ),
        child: child,
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Future<void> _setGoldenSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_kGoldenSize);
  tester.view.physicalSize = _kGoldenSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late SharedPreferences prefs;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neuroup_golden_hive');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('golden_test_box');

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('DemoLandingPage golden', (tester) async {
    await _setGoldenSurface(tester);
    await tester.pumpWidget(_wrap(const DemoLandingPage()));
    // Tek frame — sürekli tekrar eden animasyonların pumpAndSettle'ı
    // sonsuza kadar bekletmesini önlemek için deterministik ilk kare.
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(DemoLandingPage),
      matchesGoldenFile('goldens/demo_landing_page.png'),
    );
  });

  testWidgets('ProfilePage golden', (tester) async {
    await _setGoldenSurface(tester);
    await tester.pumpWidget(
      _wrap(
        const ProfilePage(),
        overrides: [
          learningProgressBoxProvider.overrideWithValue(box),
          appSettingsProvider.overrideWith(
            (ref) => AppSettingsNotifier(prefs),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(ProfilePage),
      matchesGoldenFile('goldens/profile_page.png'),
    );
  });
}
