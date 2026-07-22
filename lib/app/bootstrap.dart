import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:neuroup/core/env/env.dart';
import 'package:neuroup/core/services/logger_service.dart';

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
        final isOverflow = msg.contains('overflowed by') ||
            msg.contains('RenderFlex overflowed');
        // Overflow hataları sarı-siyah debug göstergesini tetikler.
        // Log'a yazmıyoruz — debug göstergesi de çıkmıyor.
        if (!isOverflow) {
          FlutterError.presentError(details);
          LoggerService.critical(
            'FlutterError: $msg',
            details.exception,
            details.stack,
          );
        }
      };

      Env.load;

      // Firebase is optional in dev (no google-services.json). In production
      // it must succeed.
      if (Env.firebaseConfigured) {
        try {
          await Firebase.initializeApp();
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
        await SentryFlutter.init((opts) {
          opts.dsn = Env.sentryDsn;
          opts.tracesSampleRate = Env.isProduction ? 0.2 : 1.0;
          opts.environment = Env.isProduction ? 'production' : 'development';
        }, appRunner: () => runApp(builder()));
      } else {
        runApp(builder());
      }
    },
    (error, stack) {
      LoggerService.critical('Uncaught zone error', error, stack);
    },
  );
}
