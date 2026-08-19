/// Derleme zamanı özellik bayrakları (feature flags).
///
/// `Env` sınıfındaki `--dart-define` deseniyle aynı yaklaşım: her bayrak
/// `bool.fromEnvironment` ile okunur, varsayılan olarak kapalıdır. Uzak bir
/// config servisi veya kalıcı depolama YOK — henüz buna ihtiyaç duyan bir
/// senaryo yok, eklenmesi gerektiğinde `FeatureFlags` burada genişletilir.
///
/// Örnek kullanım:
/// ```sh
/// flutter build apk --dart-define=FF_GEMINI_CHAT=true
/// ```
abstract class FeatureFlags {
  /// Gemini API ile gerçek AI Chat entegrasyonu. Kapalıyken mevcut
  /// sabit-cevap (canned response) davranışı korunur.
  static const bool geminiChatEnabled = bool.fromEnvironment(
    'FF_GEMINI_CHAT',
  );

  /// Sentry performans izleme (trace/span toplama). Kapalıyken sadece
  /// hata raporlama aktif kalır.
  static const bool sentryPerformanceEnabled = bool.fromEnvironment(
    'FF_SENTRY_PERFORMANCE',
  );
}
