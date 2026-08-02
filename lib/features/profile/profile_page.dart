import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider;
import 'package:neuroup/features/learning/presentation/providers/learning_providers.dart';
import 'package:neuroup/features/profile/presentation/badge_providers.dart';
import 'package:neuroup/shared/models/user_level.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/shared/utils/layout_helper.dart';
import 'package:neuroup/shared/widgets/level_frame.dart';

/// Tema-aware erişim: context'ten scheme alarak hardcoded token
/// yerine `Theme.of(context)` döndürür.
extension AppColorsTextX on AppColors {
  static Color textPrimary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface;
  static Color textSecondary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant;
  static Color textTertiary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
  static Color border(BuildContext c) =>
      Theme.of(c).colorScheme.outline;
  static Color surface(BuildContext c) =>
      Theme.of(c).colorScheme.surface;
  static Color surfaceAlt(BuildContext c) =>
      Theme.of(c).colorScheme.surfaceContainerHigh;
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  /// Demo unlocked rozetler.
  static const _unlockedBadgeIds = {
    'first_step',
    'streak_7',
    'helper',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final progress = ref.watch(userProgressProvider);

    final effectiveUser = user ??
        UserProfile(
          id: 'demo',
          email: 'demo@neuroup.app',
          displayName: 'Demo Kullanıcı',
          role: UserRole.student,
          level: _levelFromXp(progress.totalXp),
          xp: progress.totalXp,
          streakDays: progress.streak,
        );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ProfileHeader(user: effectiveUser),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth > 600;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: LayoutHelper.horizontalPadding(context),
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _LevelCard(user: effectiveUser),
                      const SizedBox(height: 16),
                      // Level + Rozet kart'ı (entegre). Ayarlar kartı ayrı.
                      _LevelCard(user: effectiveUser),
                      if (isWide)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _SettingsSection(user: effectiveUser),
                        )
                      else
                        const SizedBox(height: 16),
                      if (!isWide)
                        _SettingsSection(user: effectiveUser),
                      const SizedBox(height: 96),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// XP'den level hesapla. Her 100 XP'de 1 level.
  static int _levelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;
    return (totalXp ~/ 100) + 1;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final level = UserLevel(
      level: user.level,
      currentXp: user.xp,
      totalXp: user.xp,
    );
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: level.tier.color,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: level.tier.gradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      LevelFrame(
                        tier: level.tier,
                        level: level.level,
                        size: 96,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: level.tier.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final islands = ref.watch(islandsProvider);

    final totalNodes = islands.fold<int>(0, (s, i) => s + i.totalNodes);
    final completedNodes = progress.completedNodeIds.length;
    final unlocks = ref.watch(badgeUnlocksProvider);
    final unlockedCount = unlocks.length;

    final level = UserLevel(
      level: user.level,
      currentXp: user.xp,
      totalXp: user.xp,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColorsTextX.border(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP row — tier renkli sayı olarak (avatar çerçevesi zaten
          // tier'ı görsel olarak taşıyor; bu sayede çift pill yok).
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${level.currentXp}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: level.tier.color,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${level.xpForNextLevel} XP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColorsTextX.textSecondary(context),
                  ),
                ),
              ),
              const Spacer(),
              // Mini seviye pill'i — kompakt: 'SEV. 1'.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: level.tier.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SEV. ${level.level}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: level.tier.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 'Sonraki seviyeye X XP kaldı' alt metin.
          Text(
            'Sonraki seviyeye ${level.xpToNext} XP kaldı',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsTextX.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: level.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColorsTextX.surfaceAlt(context),
                valueColor: AlwaysStoppedAnimation<Color>(level.tier.color),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // İstatistikler (Streak / Tamamlanan / Toplam)
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${user.streakDays}',
                  label: 'Gün Seri',
                  color: AppColors.warning,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorsTextX.border(context),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.check_circle_rounded,
                  value: '$completedNodes',
                  label: 'Tamamlanan',
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColorsTextX.border(context),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.book_rounded,
                  value: '$totalNodes',
                  label: 'Toplam Ders',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Yatay scroll rozet listesi — telefonda kompakt, başlık
          // yok (sadece daireler). AGENTS.md gereği dinamik yükseklik
          // yerine sabit 86 px kullanılır (overflow riski yok).
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Badges.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final b = Badges.all[i];
                final isUnlocked = unlocks.containsKey(b.id);
                return _BadgeMini(
                  template: b,
                  isUnlocked: isUnlocked,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Kompakt rozet — listede tek sıra. Sadece daire + emoji;
/// Tooltip ile rozet adı + açıklaması gösterir.
class _BadgeMini extends StatelessWidget {
  const _BadgeMini({
    required this.template,
    required this.isUnlocked,
  });

  final BadgeTemplate template;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.tokensOf(context);
    final tokenscheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: isUnlocked
          ? '${template.name}: ${template.description}'
          : 'Henüz kazanılmadı: ${template.description}',
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isUnlocked
              ? template.color.withValues(alpha: 0.15)
              : tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? template.color.withValues(alpha: 0.7)
                : tokens.border.withValues(alpha: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isUnlocked ? 1 : 0.4,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? template.color.withValues(alpha: 0.18)
                      : tokenscheme.surfaceContainerHigh,
                ),
                child: Text(
                  template.emoji ?? '🏅',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isUnlocked
                    ? tokens.textPrimary
                    : tokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColorsTextX.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appSettingsProvider);
    final settings = [
      _SettingItem(
        icon: Icons.person_outline_rounded,
        title: 'Hesap Bilgileri',
        subtitle: 'Profil, e-posta, şifre',
        color: AppColors.primary,
        onTap: () => _showAccountSheet(context, ref, user),
      ),
      _SettingItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        subtitle: prefs.notificationsEnabled
            ? 'Açık · push, e-posta, ses'
            : 'Kapalı',
        color: AppColors.warning,
        onTap: () => _showNotificationsSheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.palette_outlined,
        title: 'Görünüm',
        subtitle:
            '${_themeLabel(prefs.themeMode)} · ${_langLabel(prefs.language)} · '
            '${(prefs.textScale * 100).round()}%',
        color: AppColors.accent,
        onTap: () => _showAppearanceSheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.shield_outlined,
        title: 'Gizlilik',
        subtitle: prefs.analyticsEnabled
            ? 'Anonim analiz: açık'
            : 'Anonim analiz: kapalı',
        color: AppColors.info,
        onTap: () => _showPrivacySheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.help_outline_rounded,
        title: 'Yardım & Destek',
        subtitle: 'SSS, bizimle iletişim',
        color: AppColors.success,
        onTap: () => _showHelpSheet(context),
      ),
      _SettingItem(
        icon: Icons.info_outline_rounded,
        title: 'Hakkında',
        subtitle: 'Sürüm 1.0.0',
        color: AppColorsTextX.textSecondary(context),
        onTap: () => _showAbout(context),
      ),
      if (user.email != 'demo@neuroup.app')
        _SettingItem(
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          subtitle: 'Hesabından çık',
          color: AppColors.error,
          onTap: () => _confirmLogout(context),
        ),
      // Reset progress (tüm öğrenme ilerlemesini sıfırlar, debug için)
      _SettingItem(
        icon: Icons.refresh_rounded,
        title: 'İlerlemeyi Sıfırla',
        subtitle: 'Tüm ada/node ilerlemesini sıfırlar',
        color: AppColorsTextX.textTertiary(context),
        onTap: () => _confirmResetProgress(context, ref),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColorsTextX.border(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < settings.length; i++) ...[
            _SettingTile(item: settings[i]),
            if (i < settings.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Divider(
                  height: 1,
                  color: AppColorsTextX.border(context).withValues(alpha: 0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---- yardımcı etiketler ----
  String _themeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Sistem',
        AppThemeMode.light => 'Açık',
        AppThemeMode.dark => 'Koyu',
      };
  String _langLabel(AppLanguage l) => switch (l) {
        AppLanguage.tr => 'Türkçe',
        AppLanguage.en => 'English',
      };

  // ---- Hesap Bilgileri sheet ----
  void _showAccountSheet(BuildContext context, WidgetRef ref, UserProfile user) {
    final nameCtl = TextEditingController(text: user.displayName);
    final emailCtl = TextEditingController(text: user.email);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesap Bilgileri',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Görünen Ad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtl,
                  enabled: user.email != 'demo@neuroup.app',
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (user.email == 'demo@neuroup.app') {
                            // Demo modda sadece snackbar göster
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profil adı kaydedildi (demo mod). '
                                  'Gerçek kayıt Firebase bağlantısı ile aktif.',
                                ),
                              ),
                            );
                          } else {
                            // Gerçek auth için save callback'i.
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil güncellendi'),
                              ),
                            );
                          }
                        },
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Bildirimler sheet ----
  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var enabled = prefs.notificationsEnabled;
        var push = prefs.pushEnabled;
        var email = prefs.emailDigest;
        var sound = prefs.soundEnabled;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bildirimler', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Bildirimlere izin ver'),
                  value: enabled,
                  onChanged: (v) {
                    setLocal(() => enabled = v);
                    ref.read(appSettingsProvider.notifier).setNotificationsEnabled(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Push bildirimler'),
                  value: push,
                  onChanged: !enabled
                      ? null
                      : (v) {
                          setLocal(() => push = v);
                          ref.read(appSettingsProvider.notifier).setPushEnabled(v);
                        },
                ),
                SwitchListTile(
                  title: const Text('E-posta özeti'),
                  value: email,
                  onChanged: !enabled
                      ? null
                      : (v) {
                          setLocal(() => email = v);
                          ref.read(appSettingsProvider.notifier).setEmailDigest(v);
                        },
                ),
                SwitchListTile(
                  title: const Text('Bildirim sesi'),
                  value: sound,
                  onChanged: !enabled
                      ? null
                      : (v) {
                          setLocal(() => sound = v);
                          ref.read(appSettingsProvider.notifier).setSoundEnabled(v);
                        },
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ---- Görünüm sheet ----
  void _showAppearanceSheet(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var theme = prefs.themeMode;
        var lang = prefs.language;
        var scale = prefs.textScale;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Görünüm', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('Tema'),
                const SizedBox(height: 4),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(value: AppThemeMode.system, label: Text('Sistem')),
                    ButtonSegment(value: AppThemeMode.light, label: Text('Açık')),
                    ButtonSegment(value: AppThemeMode.dark, label: Text('Koyu')),
                  ],
                  selected: {theme},
                  onSelectionChanged: (s) {
                    setLocal(() => theme = s.first);
                    ref.read(appSettingsProvider.notifier).setThemeMode(s.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Dil'),
                const SizedBox(height: 4),
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(value: AppLanguage.tr, label: Text('Türkçe')),
                    ButtonSegment(value: AppLanguage.en, label: Text('English')),
                  ],
                  selected: {lang},
                  onSelectionChanged: (s) {
                    setLocal(() => lang = s.first);
                    ref.read(appSettingsProvider.notifier).setLanguage(s.first);
                  },
                ),
                const SizedBox(height: 16),
                Text('Metin boyutu: ${(scale * 100).round()}%'),
                Slider(
                  value: scale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label: '${(scale * 100).round()}%',
                  onChanged: (v) {
                    setLocal(() => scale = v);
                    ref.read(appSettingsProvider.notifier).setTextScale(v);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ---- Gizlilik sheet ----
  void _showPrivacySheet(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var analytics = prefs.analyticsEnabled;
        var crash = prefs.crashReportsEnabled;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gizlilik', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Anonim analiz'),
                  subtitle: const Text('Kullanım verilerini paylaş'),
                  value: analytics,
                  onChanged: (v) {
                    setLocal(() => analytics = v);
                    ref.read(appSettingsProvider.notifier).setAnalyticsEnabled(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Çökme raporları'),
                  subtitle: const Text('Hata loglarını gönder'),
                  value: crash,
                  onChanged: (v) {
                    setLocal(() => crash = v);
                    ref.read(appSettingsProvider.notifier).setCrashReportsEnabled(v);
                  },
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ---- Yardım sheet ----
  void _showHelpSheet(BuildContext context) {
    final entries = const [
      _FaqEntry(
        q: 'Nasıl ders tamamlarım?',
        a: 'Bir adaya tıkla, ders kodunu yaz veya örnek çözümü uygula, '
            'Çalıştır butonuna bas. Çıktı doğruysa DOĞRU rozeti görünür, '
            'ardından +XP butonu aktif olur.',
      ),
      _FaqEntry(
        q: 'Bir sonraki ada nasıl açılır?',
        a: 'Bir önceki adanın tüm derslerini tamamla. Ada tamamen '
            'tamamlanınca bir sonraki ada otomatik açılır.',
      ),
      _FaqEntry(
        q: 'XP ve seviye nasıl çalışır?',
        a: 'Her ders belirli XP verir. Her 100 XP 1 level atlatır. '
            'Bronze → Silver → Gold → Diamond → Master tierları var.',
      ),
      _FaqEntry(
        q: 'Reels vitrin nedir?',
        a: 'Geliştirici topluluğunun oyun demosu paylaştığı kısa video '
            'akışıdır. Beğeni, yorum ve CTA butonları içerir.',
      ),
      _FaqEntry(
        q: 'Demo modda veriler kaydedilir mi?',
        a: 'Hayır. Demo modda tüm veriler in-memory çalışır. Firebase '
            'bağlantısı gerçek kayıt için gereklidir.',
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorsTextX.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Text('SSS', style: Theme.of(ctx).textTheme.headlineSmall),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ExpansionTile(
                      title: Text(
                        entries[i].q,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(entries[i].a),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- About sheet ----
  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorsTextX.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Neuroup', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text(
              'Eğitim, haber, sohbet ve oyunları bir araya getiren '
              'çapraz platform öğrenme uygulaması.',
            ),
            const SizedBox(height: 20),
            const _AboutRow(label: 'Sürüm', value: '1.0.0'),
            const _AboutRow(label: 'Platform', value: 'iOS • Android • Linux'),
            const _AboutRow(label: 'Mimari', value: 'Riverpod + Clean Arch'),
            const _AboutRow(label: 'Paket', value: 'com.neuroup.app'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Logout onayı ----
  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Çıkış yapıldı (demo mod)')),
              );
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İlerlemeyi Sıfırla'),
        content: const Text(
          'Tüm ada ve ders ilerlemeniz sıfırlanır. XP ve streak de sıfırlanır. '
          'Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(learningProgressProvider.notifier).resetProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İlerleme sıfırlandı')),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _FaqEntry {
  const _FaqEntry({required this.q, required this.a});
  final String q;
  final String a;
}

class _SettingItem {
  _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.item});
  final _SettingItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
