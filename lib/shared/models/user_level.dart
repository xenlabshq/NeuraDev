import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Seviye kategorisi — profil çerçevesinde ve rozetlerde kullanılır.
enum UserTier {
  bronze(
    label: 'Bronz',
    minLevel: 1,
    color: Color(0xFFCD7F32),
    frame: 'brass',
  ),
  silver(
    label: 'Gümüş',
    minLevel: 6,
    color: Color(0xFFC0C0C0),
    frame: 'silver',
  ),
  gold(
    label: 'Altın',
    minLevel: 11,
    color: Color(0xFFFFD700),
    frame: 'gold',
  ),
  diamond(
    label: 'Elmas',
    minLevel: 21,
    color: Color(0xFFB9F2FF),
    frame: 'diamond',
  ),
  master(
    label: 'Usta',
    minLevel: 30,
    color: AppColors.primary,
    frame: 'master',
  );

  const UserTier({
    required this.label,
    required this.minLevel,
    required this.color,
    required this.frame,
  });

  final String label;
  final int minLevel;
  final Color color;
  final String frame;

  /// Computed gradient (non-const so we can use Color values).
  List<Color> get gradient {
    switch (this) {
      case UserTier.bronze:
        return const [Color(0xFFCD7F32), Color(0xFF8B4513)];
      case UserTier.silver:
        return const [Color(0xFFE8E8E8), Color(0xFFA8A8A8)];
      case UserTier.gold:
        return const [Color(0xFFFFE55C), Color(0xFFFFA000)];
      case UserTier.diamond:
        return const [Color(0xFFB9F2FF), Color(0xFF4FC3F7)];
      case UserTier.master:
        return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
    }
  }

  /// Verilen level için uygun tier.
  static UserTier forLevel(int level) {
    var current = UserTier.bronze;
    for (final tier in UserTier.values) {
      if (level >= tier.minLevel) current = tier;
    }
    return current;
  }

  /// Sonraki tier.
  UserTier? get next {
    final idx = UserTier.values.indexOf(this);
    if (idx >= UserTier.values.length - 1) return null;
    return UserTier.values[idx + 1];
  }
}

/// Kullanıcı seviye bilgisi.
class UserLevel extends Equatable {
  const UserLevel({
    required this.level,
    required this.currentXp,
    required this.totalXp,
  });

  final int level;
  final int currentXp;
  final int totalXp;

  /// Bu level için gereken XP.
  int get xpForCurrentLevel => level * 100;

  /// Sonraki level için gereken XP.
  int get xpForNextLevel => (level + 1) * 100;

  /// Progress yüzdesi (0..1).
  double get progress {
    final cur = xpForCurrentLevel;
    final next = xpForNextLevel;
    final span = next - cur;
    if (span == 0) return 0;
    return ((currentXp - cur) / span).clamp(0.0, 1.0);
  }

  UserTier get tier => UserTier.forLevel(level);

  /// Sonraki level'a kalan XP.
  int get xpToNext => xpForNextLevel - currentXp;

  /// Default — yeni kullanıcı.
  static const empty = UserLevel(level: 1, currentXp: 0, totalXp: 0);

  UserLevel copyWith({int? level, int? currentXp, int? totalXp}) => UserLevel(
        level: level ?? this.level,
        currentXp: currentXp ?? this.currentXp,
        totalXp: totalXp ?? this.totalXp,
      );

  @override
  List<Object?> get props => [level, currentXp, totalXp];
}

/// Rozet — özel başarılar.
class Badge extends Equatable {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.icon,
    this.emoji,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  @override
  List<Object?> get props =>
      [id, name, description, icon, emoji, color, unlockedAt];
}

/// Hazır rozetler.
class Badges {
  Badges._();

  static const all = <BadgeTemplate>[
    BadgeTemplate(
      id: 'first_step',
      name: 'İlk Adım',
      description: 'İlk dersini tamamla',
      emoji: '🌱',
      color: AppColors.success,
    ),
    BadgeTemplate(
      id: 'quiz_master',
      name: 'Quiz Ustası',
      description: '5 quiz\'i %90+ ile geç',
      emoji: '🎯',
      color: AppColors.accent,
    ),
    BadgeTemplate(
      id: 'streak_7',
      name: '7 Gün Seri',
      description: '7 gün üst üste giriş yap',
      emoji: '🔥',
      color: AppColors.warning,
    ),
    BadgeTemplate(
      id: 'word_champion',
      name: 'Kelime Şampiyonu',
      description: 'Kelime Avı\'nda 500 puan',
      emoji: '🏆',
      color: AppColors.gold,
    ),
    BadgeTemplate(
      id: 'math_wizard',
      name: 'Matematik Dâhisi',
      description: 'Tüm matematik derslerini tamamla',
      emoji: '🧮',
      color: AppColors.mathColor,
    ),
    BadgeTemplate(
      id: 'science_explorer',
      name: 'Bilim Kaşifi',
      description: 'Tüm fen derslerini tamamla',
      emoji: '🔬',
      color: AppColors.scienceColor,
    ),
    BadgeTemplate(
      id: 'history_buff',
      name: 'Tarih Bilgini',
      description: 'Tüm tarih derslerini tamamla',
      emoji: '🏛️',
      color: AppColors.historyColor,
    ),
    BadgeTemplate(
      id: 'helper',
      name: 'Yardımsever',
      description: 'Destek sohbetini ilk defa kullan',
      emoji: '💬',
      color: AppColors.info,
    ),
  ];
}

class BadgeTemplate extends Equatable {
  const BadgeTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.emoji,
    this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final String? emoji;
  final IconData? icon;
  final Color color;

  @override
  List<Object?> get props => [id, name, description, emoji, icon, color];
}
