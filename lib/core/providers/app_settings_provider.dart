import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tema modu — Sistem/Açık/Koyu.
enum AppThemeMode { system, light, dark }

/// Dil seçeneği.
enum AppLanguage { tr, en }

/// Kullanıcı ayarları — notifications, görünüm, gizlilik.
class AppSettings extends Equatable {
  const AppSettings({
    this.notificationsEnabled = true,
    this.pushEnabled = true,
    this.emailDigest = false,
    this.soundEnabled = true,
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.tr,
    this.textScale = 1.0,
    this.analyticsEnabled = false,
    this.crashReportsEnabled = true,
  });

  final bool notificationsEnabled;
  final bool pushEnabled;
  final bool emailDigest;
  final bool soundEnabled;
  final AppThemeMode themeMode;
  final AppLanguage language;
  final double textScale;
  final bool analyticsEnabled;
  final bool crashReportsEnabled;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? pushEnabled,
    bool? emailDigest,
    bool? soundEnabled,
    AppThemeMode? themeMode,
    AppLanguage? language,
    double? textScale,
    bool? analyticsEnabled,
    bool? crashReportsEnabled,
  }) =>
      AppSettings(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailDigest: emailDigest ?? this.emailDigest,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        textScale: textScale ?? this.textScale,
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
      );

  @override
  List<Object?> get props => [
        notificationsEnabled,
        pushEnabled,
        emailDigest,
        soundEnabled,
        themeMode,
        language,
        textScale,
        analyticsEnabled,
        crashReportsEnabled,
      ];
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void setNotificationsEnabled(bool v) =>
      state = state.copyWith(notificationsEnabled: v);
  void setPushEnabled(bool v) => state = state.copyWith(pushEnabled: v);
  void setEmailDigest(bool v) => state = state.copyWith(emailDigest: v);
  void setSoundEnabled(bool v) => state = state.copyWith(soundEnabled: v);
  void setThemeMode(AppThemeMode m) => state = state.copyWith(themeMode: m);
  void setLanguage(AppLanguage l) => state = state.copyWith(language: l);
  void setTextScale(double s) => state = state.copyWith(textScale: s);
  void setAnalyticsEnabled(bool v) =>
      state = state.copyWith(analyticsEnabled: v);
  void setCrashReportsEnabled(bool v) =>
      state = state.copyWith(crashReportsEnabled: v);

  void reset() => state = const AppSettings();
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);

/// TextScaler AppSettings.textScale'e göre: MaterialApp MediaQuery wrapper'ı.
extension AppSettingsTextScale on AppSettings {
  TextScaler get textScaler => TextScaler.linear(textScale);
}
