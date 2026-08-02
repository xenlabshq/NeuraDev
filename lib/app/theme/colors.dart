import 'package:flutter/material.dart';

/// Neuroup brand colors — modern, vibrant, professional.
/// Renk tokenleri tema-aware'dir: `AppColorTokens` üzerinden
/// dark/light için farklı değerler dönerler.
class AppColors {
  AppColors._();

  // --- Primary brand palette (her iki tema için aynı) ---
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // --- Accent (her iki tema için aynı) ---
  static const Color accent = Color(0xFFEC4899); // Pink 500
  static const Color accentLight = Color(0xFFF472B6);

  // --- Educational warm accent (her iki tema için aynı) ---
  static const Color gold = Color(0xFFFBBF24);
  static const Color orange = Color(0xFFF97316);
  static const Color coral = Color(0xFFFB7185);

  // --- Status (her iki tema için aynı) ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B5CF6);

  // --- NEUTRALS — Light mode ---
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceAltLight = Color(0xFFF5F5F7);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- NEUTRALS — Dark mode (daha açık tonlar, koyu arka plan üzerinde
  // okunabilirliği koruyacak şekilde) ---
  static const Color surfaceDark = Color(0xFF0F1117); // zengin koyu — ana bg
  static const Color surfaceAltDark = Color(0xFF1A1D26); // kart arka planı
  static const Color surfaceContainerDark = Color(0xFF232735); // yükseltilmiş
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // neredeyse beyaz
  static const Color textSecondaryDark = Color(0xFFB8BCC9); // orta gri
  static const Color textTertiaryDark = Color(0xFF7C8090); // soluk gri
  static const Color borderDark = Color(0xFF2A2E3A);

  // --- Eski sabit token'lar (geriye uyumluluk). Tema-aware erişim için
  //     aşağıdaki extension metodlarını kullanın. ---
  static const Color surface = surfaceLight;
  static const Color surfaceAlt = surfaceAltLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textTertiary = textTertiaryLight;
  static const Color border = borderLight;

  /// Aktif temaya göre nötr renkleri döndürür. `Theme.of(context)` ile
  /// birlikte kullanılmalıdır; `Widget.build()` içinden çağrılmalı.
  static NColorTokens tokensOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const _DarkColorTokens()
          : const _LightColorTokens();

  /// Tema bağımsız gradient'ler — bunlar light/dark için aynı kalır
  /// (CTA'lar, marka rozetleri, vb.).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
  );

  /// Tema-aware sayfa arka planı.
  static LinearGradient pageBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0C12), Color(0xFF14171F)],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            );

  // Category colors (her iki tema için aynı)
  static const Color mathColor = Color(0xFF6366F1);
  static const Color scienceColor = Color(0xFF10B981);
  static const Color historyColor = Color(0xFFF59E0B);
  static const Color languageColor = Color(0xFFEC4899);
  static const Color technologyColor = Color(0xFF06B6D4);
  static const Color artColor = Color(0xFF8B5CF6);
}

/// Tema-aware nötr renk tokenleri. Light/dark için farklı
/// `Color` instance'larına işaret eder. Widget build sırasında
/// `AppColors.tokensOf(context)` üzerinden alınır.
abstract class NColorTokens {
  const NColorTokens();
  Color get surface;
  Color get surfaceAlt;
  Color get surfaceContainer;
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get border;
  Color get shadow;
}

class _LightColorTokens extends NColorTokens {
  const _LightColorTokens();
  @override Color get surface => AppColors.surfaceLight;
  @override Color get surfaceAlt => AppColors.surfaceAltLight;
  @override Color get surfaceContainer => const Color(0xFFEEF0F3);
  @override Color get textPrimary => AppColors.textPrimaryLight;
  @override Color get textSecondary => AppColors.textSecondaryLight;
  @override Color get textTertiary => AppColors.textTertiaryLight;
  @override Color get border => AppColors.borderLight;
  @override Color get shadow => const Color(0x1A000000); // %10 siyah
}

class _DarkColorTokens extends NColorTokens {
  const _DarkColorTokens();
  @override Color get surface => AppColors.surfaceDark;
  @override Color get surfaceAlt => AppColors.surfaceAltDark;
  @override Color get surfaceContainer => AppColors.surfaceContainerDark;
  @override Color get textPrimary => AppColors.textPrimaryDark;
  @override Color get textSecondary => AppColors.textSecondaryDark;
  @override Color get textTertiary => AppColors.textTertiaryDark;
  @override Color get border => AppColors.borderDark;
  @override Color get shadow => const Color(0x66000000); // %40 siyah
}
