import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:neuroup/core/env/env.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/core/providers/core_providers.dart';
import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/firebase_options.dart';

final Talker talker = TalkerFlutter.init(
  settings: TalkerSettings(
    useConsoleLogs: kDebugMode,
    useHistory: kDebugMode,
    maxHistoryItems: 200,
  ),
);

Future<void> bootstrap(Widget Function() builder) async {
  // dart:ui print çağrılarını yakala — Firebase Linux'ta "no-app" yazdırıyor,
  // bunu sessizce yutuyoruz (demo modda).
  final originalPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null &&
        (message.contains('core/no-app') ||
            message.contains('has been created') ||
            message.contains('Call Firebase.initializeApp()'))) {
      return;
    }
    originalPrint(message, wrapWidth: wrapWidth);
  };

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        final isOverflow =
            msg.contains('overflowed by') ||
            msg.contains('RenderFlex overflowed') ||
            msg.contains('A RenderFlex overflowed');
        if (isOverflow) {
          // Sadece küçük (1-3 px) rounding hatalarını bastır.
          // 4+ px olan gerçek overflow AGENTS.md gereği loglanmalı.
          final pixels = _extractOverflowPixels(msg);
          if (pixels != null && pixels <= 3) {
            return;
          }
          FlutterError.presentError(details);
          LoggerService.critical(
            'Overflow ${pixels ?? '?'}px: $msg',
            details.exception,
            details.stack,
          );
          return;
        }
        FlutterError.presentError(details);
        LoggerService.critical(
          'FlutterError: $msg',
          details.exception,
          details.stack,
        );
      };

      // ErrorWidget'ı global olarak ez. Tüm RenderFlex overflow'ları için
      // sarı-siyah şerit gösterilmez (görsel olarak layout'u mahveder);
      // bunun yerine hata logger'a yazılır, ekranda sessiz kalır.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        final msg = details.exceptionAsString();
        if (msg.contains('overflowed by') ||
            msg.contains('RenderFlex overflowed')) {
          final pixels = _extractOverflowPixels(msg);
          LoggerService.critical(
            'Overflow ${pixels ?? '?'}px: $msg',
            details.exception,
            details.stack,
          );
          return const SizedBox.shrink();
        }
        return ErrorWidget(details.exception);
      };

      // Hive başlat — path_provider üzerinden uygulama dizinini al,
      // gerekli kutuları (app_settings, learning_progress, news_cache)
      // aç. Kutular HiveBoxes registry'sinden geliyor.
      await Hive.initFlutter();
      await Future.wait<void>([
        Hive.openBox<dynamic>(HiveBoxes.appSettings),
        Hive.openBox<dynamic>(HiveBoxes.learningProgress),
        Hive.openBox<dynamic>(HiveBoxes.newsCache),
      ]);

      // SharedPreferences — tema/dil/bildirim gibi küçük ayarları
      // kalıcı saklamak için.
      final prefs = await SharedPreferences.getInstance();

      // Firebase is optional in dev (no google-services.json). In production
      // it must succeed.
      if (Env.firebaseConfigured) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          // Google ile giriş — google_sign_in 7.x Android'de Credential
          // Manager kullanıyor, bu da "Web" tipli OAuth client'ı
          // serverClientId olarak açıkça ister (bkz. Env.googleServerClientId
          // yorumu). Verilmeden "No credential available" hatasıyla
          // sessizce başarısız oluyordu.
          await GoogleSignIn.instance.initialize(
            serverClientId: Env.googleServerClientId,
          );
        } catch (e, st) {
          LoggerService.error('Firebase init failed', e, st);
          if (Env.isProduction) rethrow;
        }
      } else {
        LoggerService.warn(
          'Firebase not configured — running in offline mode. '
          'Add google-services.json / firebase_options.dart to enable.',
        );
      }

      if (Env.sentryDsn.isNotEmpty) {
        await SentryFlutter.init(
          (opts) {
            opts.dsn = Env.sentryDsn;
            opts.tracesSampleRate = Env.isProduction ? 0.2 : 1.0;
            opts.environment = Env.isProduction ? 'production' : 'development';
          },
          appRunner: () {
            // Sentry açıldıktan SONRA ProviderScope'u prefs ile
            // override edip runApp çağırıyoruz; böylece AppSettings
            // persistance'lı başlar.
            runApp(
              ProviderScope(
                overrides: [
                  sharedPrefsProvider.overrideWith((_) => prefs),
                  appSettingsProvider.overrideWith(
                    (ref) => AppSettingsNotifier(prefs),
                  ),
                ],
                child: builder(),
              ),
            );
          },
        );
      } else {
        runApp(
          ProviderScope(
            overrides: [
              sharedPrefsProvider.overrideWith((_) => prefs),
              appSettingsProvider.overrideWith(
                (ref) => AppSettingsNotifier(prefs),
              ),
            ],
            child: builder(),
          ),
        );
      }
    },
    (error, stack) {
      LoggerService.critical('Uncaught zone error', error, stack);
    },
  );
}

/// RenderFlex overflow mesajından piksel sayısını çıkarır.
/// "overflowed by 5 pixels" → 5. "overflowed by 12.3 pixels" → 12 (yuvarlama).
/// Bulunamazsa null döner — bu durumda caller güvenli tarafta kalır
/// (4+ kabul edip loglar).
int? _extractOverflowPixels(String message) {
  final pattern = RegExp(r'overflowed by\s+([\d.]+)\s*pixels?');
  final match = pattern.firstMatch(message);
  if (match == null) return null;
  return double.tryParse(match.group(1) ?? '')?.round();
}
