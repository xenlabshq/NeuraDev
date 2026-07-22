import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_settings_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class NeuroupApp extends ConsumerWidget {
  const NeuroupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: 'Neuroup',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Kullanıcı ayarlarındaki metin boyutunu sistemin font ölçeğiyle birleştir.
      builder: (context, child) {
        // Sistem textScaler'ı clamp'leyip kendi textScale'imizle birleştir.
        final base = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(base.scale(14) / 14 * settings.textScale),
          ),
          child: child!,
        );
      },
    );
  }
}
