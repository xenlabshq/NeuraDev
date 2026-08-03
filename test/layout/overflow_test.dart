// Sayfa-bazlı overflow tarayıcı.
// Her sayfayı bir ProviderScope + MaterialApp içine 393x851 boyutunda
// (Pixel 5) render eder. pumpWidget sonrası hata event'lerini
// override edip RenderFlex overflow mesajı ararız.
//
// Her sayfa için AYNI test fonksiyonu kullanılır.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroup/app/pages/demo_landing_page.dart';
import 'package:neuroup/features/profile/profile_page.dart';
import 'package:neuroup/features/reels/presentation/pages/reels_page.dart';
import 'package:neuroup/features/news/presentation/pages/news_page.dart';
import 'package:neuroup/features/learning/presentation/pages/island_map_page.dart';

const Size kCompactSize = Size(320, 568); // iPhone SE — küçük telefon
const Size kPhoneSize = Size(393, 851);
const Size kTabletSize = Size(768, 1024);
const Size kWideSize = Size(916, 1440);

Widget _wrap(Widget child, {Size? size}) => ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size ?? kPhoneSize,
            platformBrightness: Brightness.dark,
            devicePixelRatio: 1.0,
          ),
          child: child,
        ),
        debugShowCheckedModeBanner: false,
      ),
    );

Future<List<String>> _renderAndCapture(
  WidgetTester tester,
  Widget widget,
) async {
  final errors = <String>[];
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
  };
  try {
    await tester.pumpWidget(_wrap(widget));
    await tester.pump(const Duration(milliseconds: 50));
  } catch (e) {
    errors.add('PUMP_EX: $e');
  } finally {
    FlutterError.onError = origOnError;
  }
  return errors;
}

List<String> _filterOverflows(List<String> errors) {
  return errors
      .where((e) => e.contains('RenderFlex overflowed') ||
          e.contains('A RenderFlex overflowed') ||
          (e.contains('overflowed by') && e.contains('pixels')))
      .toList();
}

Future<void> _overflowTest(
  WidgetTester tester,
  String name,
  Widget child, {
  Size? size,
}) async {
  final errors = <String>[];
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
  };
  try {
    await tester.pumpWidget(_wrap(child, size: size));
    await tester.pump(const Duration(milliseconds: 50));
  } catch (e) {
    errors.add('PUMP_EX: $e');
  } finally {
    FlutterError.onError = origOnError;
  }
  final ov = errors
      .where((e) => e.contains('RenderFlex overflowed') ||
          e.contains('A RenderFlex overflowed') ||
          (e.contains('overflowed by') && e.contains('pixels')))
      .toList();
  expect(ov, isEmpty, reason: '$name overflow errors:\n${ov.join("\n")}');
}

void main() {
  // iPhone SE gibi çok küçük telefon — kompakt.
  testWidgets('DemoLandingNoOverflow_Compact', (tester) async =>
      _overflowTest(tester, 'DemoLandingPage', const DemoLandingPage(),
          size: kCompactSize));
  testWidgets('ProfileNoOverflow_Compact', (tester) async =>
      _overflowTest(tester, 'ProfilePage', const ProfilePage(),
          size: kCompactSize));
  testWidgets('ReelsNoOverflow_Compact', (tester) async =>
      _overflowTest(tester, 'ReelsPage', const ReelsPage(),
          size: kCompactSize));
  testWidgets('NewsNoOverflow_Compact', (tester) async =>
      _overflowTest(tester, 'NewsPage', const NewsPage(),
          size: kCompactSize));
  testWidgets('NewsNoOverflow_Compact_TextScale15', (tester) async {
    final errors = <String>[];
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: kCompactSize,
                platformBrightness: Brightness.dark,
                devicePixelRatio: 1.0,
                textScaler: TextScaler.linear(1.5),
              ),
              child: const NewsPage(),
            ),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    } finally {
      FlutterError.onError = origOnError;
    }
    final ov = errors
        .where((e) => e.contains('overflowed') && e.contains('pixels'))
        .toList();
    expect(ov, isEmpty,
        reason: 'NewsPage compact+1.5x overflow:\n${ov.join("\n")}');
  });
  testWidgets('NewsHeader_FlexibleLongTitle_Compact', (tester) async {
    // "Haberler" başlığı artık Flexible(loose) + pill container içinde;
    // uzun metin veya büyük text scale'de RenderFlex overflow vermemeli.
    final errors = <String>[];
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: kCompactSize,
                platformBrightness: Brightness.dark,
                devicePixelRatio: 1.0,
                textScaler: TextScaler.linear(2.0),
              ),
              child: const NewsPage(),
            ),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    } finally {
      FlutterError.onError = origOnError;
    }
    final ov = errors
        .where((e) => e.contains('overflowed') && e.contains('pixels'))
        .toList();
    expect(ov, isEmpty,
        reason: 'NewsPage compact+2.0x header overflow:\n${ov.join("\n")}');
  });
  testWidgets('IslandMapNoOverflow_Compact', (tester) async =>
      _overflowTest(tester, 'IslandMapPage', const IslandMapPage(),
          size: kCompactSize));

  // Pixel 5 — standart modern telefon.
  testWidgets('ProfileNoOverflow_Phone', (tester) async =>
      _overflowTest(tester, 'ProfilePage', const ProfilePage(),
          size: kPhoneSize));
  testWidgets('ReelsNoOverflow_Phone', (tester) async =>
      _overflowTest(tester, 'ReelsPage', const ReelsPage(),
          size: kPhoneSize));
  testWidgets('NewsNoOverflow_Phone', (tester) async =>
      _overflowTest(tester, 'NewsPage', const NewsPage(),
          size: kPhoneSize));
  testWidgets('IslandMapNoOverflow_Phone', (tester) async =>
      _overflowTest(tester, 'IslandMapPage', const IslandMapPage(),
          size: kPhoneSize));

  // Tablet portrait — iPad benzeri
  testWidgets('DemoLandingNoOverflow_Tablet', (tester) async =>
      _overflowTest(tester, 'DemoLandingPage', const DemoLandingPage(),
          size: kTabletSize));
  testWidgets('ProfileNoOverflow_Tablet', (tester) async =>
      _overflowTest(tester, 'ProfilePage', const ProfilePage(),
          size: kTabletSize));
  testWidgets('ReelsNoOverflow_Tablet', (tester) async =>
      _overflowTest(tester, 'ReelsPage', const ReelsPage(),
          size: kTabletSize));
  testWidgets('NewsNoOverflow_Tablet', (tester) async =>
      _overflowTest(tester, 'NewsPage', const NewsPage(),
          size: kTabletSize));
  testWidgets('IslandMapNoOverflow_Tablet', (tester) async =>
      _overflowTest(tester, 'IslandMapPage', const IslandMapPage(),
          size: kTabletSize));

  // Wide — kullanıcının gerçek masaüstü penceresi
  testWidgets('ProfileNoOverflow_Wide', (tester) async =>
      _overflowTest(tester, 'ProfilePage', const ProfilePage(),
          size: kWideSize));
  testWidgets('ReelsNoOverflow_Wide', (tester) async =>
      _overflowTest(tester, 'ReelsPage', const ReelsPage(),
          size: kWideSize));
  testWidgets('NewsNoOverflow_Wide', (tester) async =>
      _overflowTest(tester, 'NewsPage', const NewsPage(),
          size: kWideSize));
  testWidgets('IslandMapNoOverflow_Wide', (tester) async =>
      _overflowTest(tester, 'IslandMapPage', const IslandMapPage(),
          size: kWideSize));
}