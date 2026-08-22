import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:neuroup/app/router/home_shell.dart';
import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/core/providers/app_settings_provider.dart';
import 'package:neuroup/features/admin/presentation/pages/admin_users_page.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_providers.dart'
    show authRepositoryProvider, authStateProvider;
import 'package:neuroup/features/chat/presentation/providers/chat_providers.dart'
    show currentAuthUserProvider, resolvedAuthUserProvider;
import 'package:neuroup/features/learning/presentation/providers/learning_providers.dart';
import 'package:neuroup/features/profile/presentation/badge_providers.dart';
import 'package:neuroup/features/reports/presentation/pages/reports_page.dart';
import 'package:neuroup/features/reports/presentation/providers/report_providers.dart';
import 'package:neuroup/l10n/gen/app_localizations.dart';
import 'package:neuroup/shared/models/user_level.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/shared/utils/badge_labels.dart';
import 'package:neuroup/shared/utils/layout_helper.dart';
import 'package:neuroup/shared/widgets/level_frame.dart';

/// Tema-aware erişim: context'ten scheme alarak hardcoded token
/// yerine `Theme.of(context)` döndürür.
extension AppColorsTextX on AppColors {
  static Color textPrimary(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color textSecondary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant;
  static Color textTertiary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
  static Color border(BuildContext c) => Theme.of(c).colorScheme.outline;
  static Color surface(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color surfaceAlt(BuildContext c) =>
      Theme.of(c).colorScheme.surfaceContainerHigh;
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final progress = ref.watch(userProgressProvider);
    final l10n = AppLocalizations.of(context);

    // XP/seviye/streak'in TEK doğruluk kaynağı `userProgressProvider`
    // (yerel Hive ilerlemesi) — Firebase Auth'tan gelen `UserProfile` bu
    // alanları hiç taşımaz (varsayılan xp=0/level=1 ile gelir), bu yüzden
    // gerçek modda giriş yapmış kullanıcılarda XP her zaman 0 görünürdü.
    // Kimlik alanlarını (id/email/ad/rol) `user`dan, ilerleme alanlarını
    // her zaman canlı progress'ten alarak birleştiriyoruz.
    final baseUser =
        user ??
        UserProfile(
          id: 'demo',
          email: 'demo@neuroup.app',
          displayName: l10n.demoUserDisplayName,
          role: UserRole.student,
        );
    final effectiveUser = baseUser.copyWith(
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
                      if (isWide)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _SettingsSection(user: effectiveUser),
                        )
                      else
                        const SizedBox(height: 16),
                      if (!isWide) _SettingsSection(user: effectiveUser),
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
    final l10n = AppLocalizations.of(context);

    final totalNodes = islands.fold<int>(0, (s, i) => s + i.totalNodes);
    final completedNodes = progress.completedNodeIds.length;
    final unlocks = ref.watch(badgeUnlocksProvider);

    final level = UserLevel(
      level: user.level,
      currentXp: user.xp,
      totalXp: user.xp,
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
                  l10n.xpOfTotal(level.xpForNextLevel),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: level.tier.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.levelPill(level.level),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: level.tier.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 'Sonraki seviyeye X XP kaldı' alt metin.
          Text(
            l10n.xpToNextLevel(level.xpToNext),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsTextX.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 10),
          // İstatistikler (Streak / Tamamlanan / Toplam)
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${user.streakDays}',
                  label: l10n.statStreak,
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
                  label: l10n.statCompleted,
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
                  label: l10n.statTotalLessons,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Yatay scroll rozet listesi — telefonda kompakt, başlık
          // yok (sadece daireler). AGENTS.md gereği dinamik yükseklik
          // yerine sabit 76 px kullanılır (overflow riski yok).
          SizedBox(
            height: 76,
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
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: isUnlocked
          ? '${template.localizedName(l10n)}: '
                '${template.localizedDescription(l10n)}'
          : '${l10n.badgeLockedPrefix}: '
                '${template.localizedDescription(l10n)}',
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
              template.localizedName(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isUnlocked ? tokens.textPrimary : tokens.textTertiary,
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
    final l10n = AppLocalizations.of(context);
    final settings = [
      _SettingItem(
        icon: Icons.person_outline_rounded,
        title: l10n.settingsAccountTitle,
        subtitle: l10n.settingsAccountSubtitle,
        color: AppColors.primary,
        onTap: () => _showAccountSheet(context, ref, user),
      ),
      _SettingItem(
        icon: Icons.notifications_outlined,
        title: l10n.settingsNotificationsTitle,
        subtitle: prefs.notificationsEnabled
            ? l10n.settingsNotificationsOnSubtitle
            : l10n.settingsOff,
        color: AppColors.warning,
        onTap: () => _showNotificationsSheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.palette_outlined,
        title: l10n.settingsAppearanceTitle,
        subtitle:
            '${_themeLabel(l10n, prefs.themeMode)} · '
            '${_langLabel(prefs.language)} · '
            '${(prefs.textScale * 100).round()}%',
        color: AppColors.accent,
        onTap: () => _showAppearanceSheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.shield_outlined,
        title: l10n.settingsPrivacyTitle,
        subtitle: prefs.analyticsEnabled
            ? l10n.settingsAnalyticsOn
            : l10n.settingsAnalyticsOff,
        color: AppColors.info,
        onTap: () => _showPrivacySheet(context, ref),
      ),
      _SettingItem(
        icon: Icons.help_outline_rounded,
        title: l10n.settingsHelpTitle,
        subtitle: l10n.settingsHelpSubtitle,
        color: AppColors.success,
        onTap: () => _showHelpSheet(context),
      ),
      _SettingItem(
        icon: Icons.info_outline_rounded,
        title: l10n.settingsAboutTitle,
        subtitle: l10n.settingsAboutSubtitle,
        color: AppColorsTextX.textSecondary(context),
        onTap: () => _showAbout(context),
      ),
      if (user.role == UserRole.admin)
        _SettingItem(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.settingsAdminTitle,
          subtitle: l10n.settingsAdminSubtitle,
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminUsersPage()),
          ),
        ),
      if (user.role.isSupportStaff)
        _SettingItem(
          icon: Icons.flag_outlined,
          title: l10n.settingsReportsTitle,
          subtitle: () {
            final pending = ref
                .watch(pendingReportsStreamProvider)
                .valueOrNull
                ?.length;
            return pending != null && pending > 0
                ? l10n.settingsReportsPendingCount(pending)
                : l10n.settingsReportsSubtitle;
          }(),
          color: AppColors.error,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReportsPage()),
          ),
        ),
      _SettingItem(
        icon: Icons.logout_rounded,
        title: l10n.settingsLogoutTitle,
        subtitle: l10n.settingsLogoutSubtitle,
        color: AppColors.error,
        onTap: () => _confirmLogout(context, ref),
      ),
      // Reset progress (tüm öğrenme ilerlemesini sıfırlar, debug için)
      _SettingItem(
        icon: Icons.refresh_rounded,
        title: l10n.settingsResetProgressTitle,
        subtitle: l10n.settingsResetProgressSubtitle,
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
  String _themeLabel(AppLocalizations l10n, AppThemeMode m) => switch (m) {
    AppThemeMode.system => l10n.themeSystem,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
  };
  String _langLabel(AppLanguage l) => switch (l) {
    AppLanguage.tr => 'Türkçe',
    AppLanguage.en => 'English',
  };

  // ---- Hesap Bilgileri sheet ----
  void _showAccountSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) {
    final l10n = AppLocalizations.of(context);
    final nameCtl = TextEditingController(text: user.displayName);
    final emailCtl = TextEditingController(text: user.email);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          // Yüzen alt barın altında kalmaması için margin bottom
          // yeterince büyük olmalı (kBottomBarHeight + alt safe area).
          child: Container(
            margin: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              // Klavye açıksa sadece viewInsets'e göre konumlan; bar
              // genelde gizli sayılır (sheet onu örter). Aksi halde
              // bar + safe area kadar boşluk bırak.
              MediaQuery.of(ctx).viewInsets.bottom > 0
                  ? 12
                  : kBottomBarHeight + 12,
            ),
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
                  l10n.accountSheetTitle,
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtl,
                  decoration: InputDecoration(
                    labelText: l10n.displayNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtl,
                  // E-posta şimdilik değiştirilemez — sadece görüntüleme.
                  // Gerçek e-posta değişimi doğrulama (mevcut e-postaya
                  // link, yeniden kimlik doğrulama) gerektirir; bu akış
                  // henüz yok, bu yüzden alan bilinçli olarak kilitli.
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    border: const OutlineInputBorder(),
                    helperText: l10n.emailNotEditableHelper,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final newName = nameCtl.text.trim();
                          if (newName.isEmpty) return;
                          final result = await ref
                              .read(authRepositoryProvider)
                              .updateProfile(
                                user.copyWith(displayName: newName),
                              );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!context.mounted) return;
                          result.when(
                            success: (_) {
                              ref.invalidate(resolvedAuthUserProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileUpdated),
                                ),
                              );
                            },
                            failure: (f) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(f.message)),
                                ),
                          );
                        },
                        child: Text(l10n.actionSave),
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
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var enabled = prefs.notificationsEnabled;
        var push = prefs.pushEnabled;
        var email = prefs.emailDigest;
        var sound = prefs.soundEnabled;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              // Klavyenin altında kalmamak için viewInsets, yüzen alt
              // bar için kBottomBarHeight.
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom > 0
                    ? MediaQuery.of(ctx).viewInsets.bottom
                    : kBottomBarHeight + 12,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                      bottom: Radius.circular(28),
                    ),
                  ),
                  // SwitchListTile ink splashes — Material ile sarılmazsa
                  // Container'ın rengi splash'ı gizler. Bu yüzden tüm
                  // içeriği Material içine alıyoruz; aynı zamanda içeriği
                  // SingleChildScrollView ile sarıp olası RenderFlex
                  // overflow'u önlüyoruz.
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Text(
                                  l10n.settingsNotificationsTitle,
                                  style: Theme.of(ctx).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile(
                            title: Text(l10n.notifAllowLabel),
                            value: enabled,
                            onChanged: (v) {
                              setLocal(() => enabled = v);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setNotificationsEnabled(v);
                            },
                          ),
                          SwitchListTile(
                            title: Text(l10n.notifPushLabel),
                            value: push,
                            onChanged: !enabled
                                ? null
                                : (v) {
                                    setLocal(() => push = v);
                                    ref
                                        .read(appSettingsProvider.notifier)
                                        .setPushEnabled(v);
                                  },
                          ),
                          SwitchListTile(
                            title: Text(l10n.notifEmailDigestLabel),
                            value: email,
                            onChanged: !enabled
                                ? null
                                : (v) {
                                    setLocal(() => email = v);
                                    ref
                                        .read(appSettingsProvider.notifier)
                                        .setEmailDigest(v);
                                  },
                          ),
                          SwitchListTile(
                            title: Text(l10n.notifSoundLabel),
                            value: sound,
                            onChanged: !enabled
                                ? null
                                : (v) {
                                    setLocal(() => sound = v);
                                    ref
                                        .read(appSettingsProvider.notifier)
                                        .setSoundEnabled(v);
                                  },
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(l10n.actionOk),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- Görünüm sheet ----
  void _showAppearanceSheet(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var theme = prefs.themeMode;
        var lang = prefs.language;
        var scale = prefs.textScale;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            // Dil değişimini bu sheet'in kendi etiketlerine de yansıtmak
            // için l10n her rebuild'de burada (dış context değil, ctx ile)
            // yeniden çözülüyor — aksi halde kullanıcı dili değiştirdiğinde
            // sheet'in kendi metinleri (Görünüm/Tema/Dil...) eski dilde
            // takılı kalıyordu.
            final l10n = AppLocalizations.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom > 0
                    ? MediaQuery.of(ctx).viewInsets.bottom
                    : kBottomBarHeight + 12,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                      bottom: Radius.circular(28),
                    ),
                  ),
                  // SingleChildScrollView ile olası RenderFlex overflow
                  // önlendi (küçük pencerede butonlar sığmazsa scroll).
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.settingsAppearanceTitle,
                            style: Theme.of(ctx).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(l10n.appearanceThemeLabel),
                          const SizedBox(height: 4),
                          SegmentedButton<AppThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: AppThemeMode.system,
                                label: Text(l10n.themeSystem),
                              ),
                              ButtonSegment(
                                value: AppThemeMode.light,
                                label: Text(l10n.themeLight),
                              ),
                              ButtonSegment(
                                value: AppThemeMode.dark,
                                label: Text(l10n.themeDark),
                              ),
                            ],
                            selected: {theme},
                            onSelectionChanged: (s) {
                              setLocal(() => theme = s.first);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setThemeMode(s.first);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.appearanceLanguageLabel),
                          const SizedBox(height: 4),
                          SegmentedButton<AppLanguage>(
                            segments: const [
                              ButtonSegment(
                                value: AppLanguage.tr,
                                label: Text('Türkçe'),
                              ),
                              ButtonSegment(
                                value: AppLanguage.en,
                                label: Text('English'),
                              ),
                            ],
                            selected: {lang},
                            onSelectionChanged: (s) {
                              setLocal(() => lang = s.first);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setLanguage(s.first);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.appearanceTextSize((scale * 100).round()),
                          ),
                          Slider(
                            value: scale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            label: '${(scale * 100).round()}%',
                            onChanged: (v) {
                              setLocal(() => scale = v);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setTextScale(v);
                            },
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(l10n.actionOk),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- Gizlilik sheet ----
  void _showPrivacySheet(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(appSettingsProvider);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var analytics = prefs.analyticsEnabled;
        var crash = prefs.crashReportsEnabled;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom > 0
                    ? MediaQuery.of(ctx).viewInsets.bottom
                    : kBottomBarHeight + 12,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                      bottom: Radius.circular(28),
                    ),
                  ),
                  // SwitchListTile ink splashes — Material ile sarılmazsa
                  // Container rengi splash'ı gizler. Aynı zamanda içerik
                  // SingleChildScrollView ile sarılarak olası RenderFlex
                  // overflow önlendi.
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Text(
                                  l10n.settingsPrivacyTitle,
                                  style: Theme.of(ctx).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile(
                            title: Text(l10n.privacyAnalyticsLabel),
                            subtitle: Text(l10n.privacyAnalyticsSubtitle),
                            value: analytics,
                            onChanged: (v) {
                              setLocal(() => analytics = v);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setAnalyticsEnabled(v);
                            },
                          ),
                          SwitchListTile(
                            title: Text(l10n.privacyCrashReportsLabel),
                            subtitle: Text(l10n.privacyCrashReportsSubtitle),
                            value: crash,
                            onChanged: (v) {
                              setLocal(() => crash = v);
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setCrashReportsEnabled(v);
                            },
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(l10n.actionOk),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- Yardım sheet ----
  void _showHelpSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      _FaqEntry(q: l10n.faqQ1, a: l10n.faqA1),
      _FaqEntry(q: l10n.faqQ2, a: l10n.faqA2),
      _FaqEntry(q: l10n.faqQ3, a: l10n.faqA3),
      _FaqEntry(q: l10n.faqQ4, a: l10n.faqA4),
      _FaqEntry(q: l10n.faqQ5, a: l10n.faqA5),
    ];
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                      Text(
                        l10n.faqTitle,
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.actionClose,
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
                    padding: EdgeInsets.fromLTRB(
                      8,
                      8,
                      8,
                      // Yüzen alt barın altında kalmaması için scroll
                      // içeriğinin altına kBottomBarHeight kadar
                      // boşluk ekle.
                      kBottomBarHeight,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ExpansionTile(
                      title: Text(
                        entries[i].q,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
  Future<void> _showAbout(BuildContext context) async {
    // Gerçek sürümü pubspec.yaml'dan derlenen APK/bundle'ın kendisinden
    // okur — hardcoded bir string gibi build'den bağımsız kalıp
    // güncellenmeyi unutma riski taşımaz.
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final versionText = '${packageInfo.version}+${packageInfo.buildNumber}';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Yüzen alt barın altında kalmaması için bottom padding'i
      // kendi içermeyen sheet'lerde SafeArea(bottom) kullanmak
      // yeterli değil — sheet tüm ekranı kaplar. Burada bottom
      // padding'i `kBottomBarHeight + safe_area` kadar ekliyoruz.
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: kBottomBarHeight + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
                bottom: Radius.circular(28),
              ),
            ),
            // SingleChildScrollView ile küçük pencerelerde olası
            // RenderFlex overflow (textScale > 1.0 ile 3 px + hataları)
            // önlendi.
            child: SingleChildScrollView(
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
                  Text(
                    'Neuroup',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  _AboutRow(
                    label: l10n.aboutVersionLabel,
                    value: versionText,
                  ),
                  _AboutRow(
                    label: l10n.aboutPlatformLabel,
                    value: 'iOS • Android • Linux',
                  ),
                  _AboutRow(
                    label: l10n.aboutArchitectureLabel,
                    value: 'Riverpod + Clean Arch',
                  ),
                  _AboutRow(
                    label: l10n.aboutPackageLabel,
                    value: 'com.neuroup.app',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionClose),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Logout onayı ----
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogoutTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Gerçek oturumu kapat — authStateChanges() bunu yakalayıp
              // currentAuthUserProvider'ı null yapar, router /login'e
              // yönlendirir.
              await ref.read(authStateProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.loggedOutMessage)),
              );
            },
            child: Text(l10n.settingsLogoutTitle),
          ),
        ],
      ),
    );
  }

  void _confirmResetProgress(BuildContext context, WidgetRef ref) {
    // İki aşamalı onay: önce bilgilendirme + uyarı diyaloğu,
    // ardından kullanıcının onay kelimesini yazmasını isteyen doğrulama
    // adımı. Yanlışlıkla tıklamayı engelleyen en güvenli kalıptır.
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.warning_rounded,
            color: AppColors.error,
            size: 32,
          ),
        ),
        iconPadding: const EdgeInsets.only(top: 12),
        title: Text(
          l10n.settingsResetProgressTitle,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resetProgressWarning,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResetConsequenceRow(
                    icon: Icons.school_outlined,
                    text: l10n.resetConsequenceIslands,
                  ),
                  const SizedBox(height: 6),
                  _ResetConsequenceRow(
                    icon: Icons.star_outline_rounded,
                    text: l10n.resetConsequenceXp,
                  ),
                  const SizedBox(height: 6),
                  _ResetConsequenceRow(
                    icon: Icons.local_fire_department_outlined,
                    text: l10n.resetConsequenceStreak,
                  ),
                  const SizedBox(height: 6),
                  _ResetConsequenceRow(
                    icon: Icons.emoji_events_outlined,
                    text: l10n.resetConsequenceBadges,
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // İptal — sol (güvenli yol, görsel olarak ayrıştırılmış).
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionGiveUp),
          ),
          // Devam Et — sağ, dikkat çekici ama henüz tehlikeli değil.
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showResetFinalConfirm(context, ref);
            },
            child: Text(l10n.actionContinue),
          ),
        ],
      ),
    );
  }

  /// İkinci aşama: onay kelimesini yazma gerektiren sıkı onay.
  void _showResetFinalConfirm(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final confirmWord = l10n.resetConfirmWord;
    final ctl = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool matches = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              icon: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
              title: Text(
                l10n.finalConfirmTitle,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.finalConfirmInstruction(confirmWord),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: confirmWord,
                    ),
                    onChanged: (v) {
                      setLocal(() => matches = v.trim() == confirmWord);
                    },
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.actionGiveUp),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: matches
                      ? () {
                          Navigator.of(ctx).pop();
                          ref
                              .read(learningProgressProvider.notifier)
                              .resetProgress();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.progressResetMessage),
                            ),
                          );
                        }
                      : null,
                  child: Text(l10n.settingsResetProgressTitle),
                ),
              ],
            );
          },
        );
      },
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sıfırlama sonucu silinecek verileri tek satırda gösterir.
class _ResetConsequenceRow extends StatelessWidget {
  const _ResetConsequenceRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.error.withValues(alpha: 0.85)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
