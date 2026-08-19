import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) => AppSettings(
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

/// SharedPreferences anahtarları.
class _Keys {
  _Keys._();
  static const notificationsEnabled = 'settings.notifications';
  static const pushEnabled = 'settings.push';
  static const emailDigest = 'settings.emailDigest';
  static const soundEnabled = 'settings.sound';
  static const themeMode = 'settings.themeMode';
  static const language = 'settings.language';
  static const textScale = 'settings.textScale';
  static const analyticsEnabled = 'settings.analytics';
  static const crashReportsEnabled = 'settings.crashReports';
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    state = AppSettings(
      notificationsEnabled: _prefs.getBool(_Keys.notificationsEnabled) ?? true,
      pushEnabled: _prefs.getBool(_Keys.pushEnabled) ?? true,
      emailDigest: _prefs.getBool(_Keys.emailDigest) ?? false,
      soundEnabled: _prefs.getBool(_Keys.soundEnabled) ?? true,
      themeMode: _parseThemeMode(_prefs.getString(_Keys.themeMode)),
      language: _parseLanguage(_prefs.getString(_Keys.language)),
      textScale: _prefs.getDouble(_Keys.textScale) ?? 1.0,
      analyticsEnabled: _prefs.getBool(_Keys.analyticsEnabled) ?? false,
      crashReportsEnabled: _prefs.getBool(_Keys.crashReportsEnabled) ?? true,
    );
  }

  void _persist(AppSettings next) {
    _prefs.setBool(_Keys.notificationsEnabled, next.notificationsEnabled);
    _prefs.setBool(_Keys.pushEnabled, next.pushEnabled);
    _prefs.setBool(_Keys.emailDigest, next.emailDigest);
    _prefs.setBool(_Keys.soundEnabled, next.soundEnabled);
    _prefs.setString(_Keys.themeMode, next.themeMode.name);
    _prefs.setString(_Keys.language, next.language.name);
    _prefs.setDouble(_Keys.textScale, next.textScale);
    _prefs.setBool(_Keys.analyticsEnabled, next.analyticsEnabled);
    _prefs.setBool(_Keys.crashReportsEnabled, next.crashReportsEnabled);
  }

  void _update(AppSettings next) {
    state = next;
    _persist(next);
  }

  static AppThemeMode _parseThemeMode(String? raw) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.system,
    );
  }

  static AppLanguage _parseLanguage(String? raw) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == raw,
      orElse: () => AppLanguage.tr,
    );
  }

  void setNotificationsEnabled(bool v) =>
      _update(state.copyWith(notificationsEnabled: v));
  void setPushEnabled(bool v) => _update(state.copyWith(pushEnabled: v));
  void setEmailDigest(bool v) => _update(state.copyWith(emailDigest: v));
  void setSoundEnabled(bool v) => _update(state.copyWith(soundEnabled: v));
  void setThemeMode(AppThemeMode m) => _update(state.copyWith(themeMode: m));
  void setLanguage(AppLanguage l) => _update(state.copyWith(language: l));
  void setTextScale(double s) => _update(state.copyWith(textScale: s));
  void setAnalyticsEnabled(bool v) =>
      _update(state.copyWith(analyticsEnabled: v));
  void setCrashReportsEnabled(bool v) =>
      _update(state.copyWith(crashReportsEnabled: v));

  void reset() {
    final defaults = const AppSettings();
    _update(defaults);
  }
}

/// ProviderSharedPreferences başlatıldıktan SONRA okunmalı;
/// `bootstrap.dart`'ta FutureProvider çözüldükten sonra
/// `appSettingsProvider`'ın override edilmesi gerekir.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => throw UnimplementedError(
        'appSettingsProvider must be overridden in ProviderScope after '
        'SharedPreferences.getInstance() resolves. See bootstrap.dart.',
      ),
    );

/// TextScaler AppSettings.textScale'e göre: MaterialApp MediaQuery wrapper'ı.
extension AppSettingsTextScale on AppSettings {
  TextScaler get textScaler => TextScaler.linear(textScale);
}
