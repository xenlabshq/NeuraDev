import 'package:flutter/material.dart';

/// Neuroup brand colors — modern, vibrant, professional.
class AppColors {
  AppColors._();

  // Primary brand palette
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Accent
  static const Color accent = Color(0xFFEC4899); // Pink 500
  static const Color accentLight = Color(0xFFF472B6);

  // Educational warm accent
  static const Color gold = Color(0xFFFBBF24);
  static const Color orange = Color(0xFFF97316);
  static const Color coral = Color(0xFFFB7185);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B5CF6);

  // Neutrals
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceAlt = Color(0xFFF5F5F7);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  // Gradients
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

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
  );

  // Category colors
  static const Color mathColor = Color(0xFF6366F1);
  static const Color scienceColor = Color(0xFF10B981);
  static const Color historyColor = Color(0xFFF59E0B);
  static const Color languageColor = Color(0xFFEC4899);
  static const Color technologyColor = Color(0xFF06B6D4);
  static const Color artColor = Color(0xFF8B5CF6);
}
