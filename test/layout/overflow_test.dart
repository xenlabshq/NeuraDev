// Sayfa-bazlı overflow tarayıcı.
// Her sayfayı bir ProviderScope + MaterialApp içine 393x851 boyutunda
// (Pixel 5) render eder. pumpWidget sonrası hata event'lerini
// override edip hataları toplarız.
//
// ÖNEMLİ: Sadece "overflow" içeren hataları değil, YAKALANAN TÜM
// hataları kontrol ediyoruz. Önceden sadece overflow-pattern
// filtreleniyordu; bu, ProfilePage ve IslandMapPage'in gerekli provider
// override'ları (Hive box, appSettingsProvider) verilmeden aslında
// çöktüğünü fark etmeden testlerin "geçmesine" sebep oluyordu.
//
// Her sayfa için AYNI test fonksiyonu kullanılır.

import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neuroup/l10n/gen/app_localizations.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/features/auth/domain/repositories/auth_repository.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_providers.dart';
import 'package:neuroup/features/learning/presentation/pages/island_map_page.dart';
import 'package:neuroup/features/news/data/services/messaging_service.dart';
import 'package:neuroup/features/news/presentation/pages/news_page.dart';
import 'package:neuroup/features/profile/profile_page.dart';
import 'package:neuroup/features/reels/data/in_memory_reel_submission_repository.dart';
import 'package:neuroup/features/reels/presentation/pages/reels_page.dart';
import 'package:neuroup/features/reels/presentation/providers/reels_providers.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Testte gerçek FCM'e dokunmadan NewsPage.initState()'in
/// `subscribeToDefaultTopics()` çağrısını yutar.
class _FakeMessagingService extends MessagingService {
  _FakeMessagingService(super.ref);
  @override
  Future<void> subscribeToDefaultTopics() async {}
}

const Size kCompactSize = Size(320, 568); // iPhone SE — küçük telefon
const Size kPhoneSize = Size(393, 851);
const Size kTabletSize = Size(768, 1024);
const Size kWideSize = Size(916, 1440);

// Klasik 3 tuşlu (gesture olmayan) Android navigasyonunun tipik sistem
// çubuğu yüksekliği — gesture nav'da bu değer 0'a yakınken, 3 tuşlu
// navigasyonda ~48'e çıkabiliyor. `bottomInset` bu senaryoyu simüle
// etmek için kullanılıyor (bkz. IslandMapNoOverflow_ThreeButtonNav).
const double kThreeButtonNavInset = 48;

Widget _wrap(
  Widget child, {
  Size? size,
  double bottomInset = 0,
  List<Override> overrides = const [],
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    // Uygulamanın varsayılan dili Türkçe — test ortamının locale'i
    // farklıysa (genelde en_US) metin uzunlukları değişip yanlış
    // overflow'lar tetikler.
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: MediaQueryData(
        size: size ?? kPhoneSize,
        platformBrightness: Brightness.dark,
        devicePixelRatio: 1.0,
        padding: EdgeInsets.only(bottom: bottomInset),
        viewPadding: EdgeInsets.only(bottom: bottomInset),
      ),
      child: child,
    ),
    debugShowCheckedModeBanner: false,
  ),
);

Future<void> _overflowTest(
  WidgetTester tester,
  String name,
  Widget child, {
  Size? size,
  double bottomInset = 0,
  List<Override> overrides = const [],
}) async {
  final errors = <String>[];
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
  };
  try {
    await tester.pumpWidget(
      _wrap(child, size: size, bottomInset: bottomInset, overrides: overrides),
    );
    await tester.pump(const Duration(milliseconds: 50));
  } catch (e) {
    errors.add('PUMP_EX: $e');
  } finally {
    FlutterError.onError = origOnError;
  }
  expect(errors, isEmpty, reason: '$name errors:\n${errors.join("\n")}');
}

void main() {
  // ProfilePage ve IslandMapPage, learningProgressProvider üzerinden bir
  // Hive box'a ve appSettingsProvider'a ihtiyaç duyuyor — gerçek uygulamada
  // bootstrap.dart bunları açıp override ediyor, testte de aynısını
  // yapmamız gerekiyor.
  late Directory tempDir;
  late Box<dynamic> box;
  late SharedPreferences prefs;
  late List<Override> learningOverrides;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neuroup_overflow_hive');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('overflow_test_box');

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    final mockAuthRepo = _MockAuthRepository();
    when(
      () => mockAuthRepo.authStateChanges(),
    ).thenAnswer((_) => Stream<UserProfile?>.value(null));

    learningOverrides = [
      learningProgressBoxProvider.overrideWithValue(box),
      appSettingsProvider.overrideWith((ref) => AppSettingsNotifier(prefs)),
      authRepositoryProvider.overrideWithValue(mockAuthRepo),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      firebaseMessagingServiceProvider.overrideWith(
        (ref) => _FakeMessagingService(ref),
      ),
      // reelsProvider, ReelsPage hiç ekrana gelmeden reelSubmissionRepository
      // Firestore/Storage'a bağlanır (bkz. reels_providers.dart) — testte
      // gerçek Firebase Storage olmadığı için in-memory'ye override ediyoruz.
      reelSubmissionRepositoryProvider.overrideWithValue(
        InMemoryReelSubmissionRepository(),
      ),
    ];
  });

  tearDownAll(() async {
    await box.close();
    await tempDir.delete(recursive: true);
  });

  // iPhone SE gibi çok küçük telefon — kompakt.
  testWidgets(
    'ProfileNoOverflow_Compact',
    (tester) async => _overflowTest(
      tester,
      'ProfilePage',
      const ProfilePage(),
      size: kCompactSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'ReelsNoOverflow_Compact',
    (tester) async => _overflowTest(
      tester,
      'ReelsPage',
      const ReelsPage(),
      size: kCompactSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'NewsNoOverflow_Compact',
    (tester) async => _overflowTest(
      tester,
      'NewsPage',
      const NewsPage(),
      size: kCompactSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets('NewsNoOverflow_Compact_TextScale15', (tester) async {
    final errors = <String>[];
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: learningOverrides,
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
    expect(
      errors,
      isEmpty,
      reason: 'NewsPage compact+1.5x errors:\n${errors.join("\n")}',
    );
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
          overrides: learningOverrides,
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
    expect(
      errors,
      isEmpty,
      reason: 'NewsPage compact+2.0x header errors:\n${errors.join("\n")}',
    );
  });
  testWidgets(
    'IslandMapNoOverflow_Compact',
    (tester) async => _overflowTest(
      tester,
      'IslandMapPage',
      const IslandMapPage(),
      size: kCompactSize,
      overrides: learningOverrides,
    ),
  );

  // Pixel 5 — standart modern telefon.
  testWidgets(
    'ProfileNoOverflow_Phone',
    (tester) async => _overflowTest(
      tester,
      'ProfilePage',
      const ProfilePage(),
      size: kPhoneSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'ReelsNoOverflow_Phone',
    (tester) async => _overflowTest(
      tester,
      'ReelsPage',
      const ReelsPage(),
      size: kPhoneSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'NewsNoOverflow_Phone',
    (tester) async => _overflowTest(
      tester,
      'NewsPage',
      const NewsPage(),
      size: kPhoneSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'IslandMapNoOverflow_Phone',
    (tester) async => _overflowTest(
      tester,
      'IslandMapPage',
      const IslandMapPage(),
      size: kPhoneSize,
      overrides: learningOverrides,
    ),
  );

  // Tablet portrait — iPad benzeri
  testWidgets(
    'ProfileNoOverflow_Tablet',
    (tester) async => _overflowTest(
      tester,
      'ProfilePage',
      const ProfilePage(),
      size: kTabletSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'ReelsNoOverflow_Tablet',
    (tester) async => _overflowTest(
      tester,
      'ReelsPage',
      const ReelsPage(),
      size: kTabletSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'NewsNoOverflow_Tablet',
    (tester) async => _overflowTest(
      tester,
      'NewsPage',
      const NewsPage(),
      size: kTabletSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'IslandMapNoOverflow_Tablet',
    (tester) async => _overflowTest(
      tester,
      'IslandMapPage',
      const IslandMapPage(),
      size: kTabletSize,
      overrides: learningOverrides,
    ),
  );

  // Wide — kullanıcının gerçek masaüstü penceresi
  testWidgets(
    'ProfileNoOverflow_Wide',
    (tester) async => _overflowTest(
      tester,
      'ProfilePage',
      const ProfilePage(),
      size: kWideSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'ReelsNoOverflow_Wide',
    (tester) async => _overflowTest(
      tester,
      'ReelsPage',
      const ReelsPage(),
      size: kWideSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'NewsNoOverflow_Wide',
    (tester) async => _overflowTest(
      tester,
      'NewsPage',
      const NewsPage(),
      size: kWideSize,
      overrides: learningOverrides,
    ),
  );
  testWidgets(
    'IslandMapNoOverflow_Wide',
    (tester) async => _overflowTest(
      tester,
      'IslandMapPage',
      const IslandMapPage(),
      size: kWideSize,
      overrides: learningOverrides,
    ),
  );

  // Regresyon: klasik 3 tuşlu Android navigasyonu (gesture değil) —
  // gerçek bir cihazda yüzen alt bar ile adaların/sistem çubuğuyla
  // çakıştığı bildirildi. `kBottomBarHeight` + sabit bir sayı yerine
  // gerçek MediaQuery.paddingOf(context).bottom eklenerek düzeltildi;
  // bu test o hesaplamanın negatif/çakışan bir boyuta yol açmadığını
  // (yani sayfanın hâlâ hatasız render edildiğini) doğruluyor.
  testWidgets(
    'IslandMapNoOverflow_ThreeButtonNav',
    (tester) async => _overflowTest(
      tester,
      'IslandMapPage',
      const IslandMapPage(),
      size: kPhoneSize,
      bottomInset: kThreeButtonNavInset,
      overrides: learningOverrides,
    ),
  );
}
