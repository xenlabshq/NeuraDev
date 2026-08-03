import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation bar için ayrılan toplam yükseklik
/// (margin + bar içerik + alt safe area).
const double kBottomBarHeight = 84;

/// Shell'in altındaki floating tab bar'ın geçici olarak gizlenmesini
/// gerektiren aktif "ders katmanı" sayacı.
///
/// `Navigator.push` ile açılan tam-sayfa ders ekranları
/// (`IslandDetailPage`, `NodeEditorPage`) bu sayacı initState'de
/// arttırıp dispose'da azaltır. Sayaç > 0 olduğunda `HomeShell` alt
/// barı gizler — böylece alt sayfadaki "Devam Et" / "Çözüm" / "+70 XP"
/// düğmeleri barın altında kalmaz.
final lessonOverlayDepthProvider = StateProvider<int>((ref) => 0);

/// Ders katmanı açıkken sayaçtaki yerini güvenle tutup bırakmak için
/// yardımcı. Widget'ın `initState` ve `dispose`'unda kullanılır.
///
/// Riverpod provider'ı widget lifecycle içinde (initState/dispose)
/// doğrudan değiştirmek yasak olduğu için arttırma/azaltma bir
/// sonraki frame'e ertelenir. Container, `initState` sırasında
/// bir kez alınır; `dispose` sırasında widget deactivated olacağı
/// için context tekrar kullanılmaz.
class LessonOverlayScope {
  LessonOverlayScope(BuildContext context)
      : _container = ProviderScope.containerOf(context, listen: false) {
    final container = _container;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      container.read(lessonOverlayDepthProvider.notifier).state++;
    });
  }

  final ProviderContainer _container;

  void dispose() {
    final container = _container;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = container.read(lessonOverlayDepthProvider);
      if (current > 0) {
        container.read(lessonOverlayDepthProvider.notifier).state =
            current - 1;
      }
    });
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({required this.child, super.key});
  final Widget child;

  static const _tabs = [
    _TabItem(
      route: '/lessons',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Dersler',
    ),
    _TabItem(
      route: '/reels',
      icon: Icons.movie_filter_outlined,
      activeIcon: Icons.movie_filter_rounded,
      label: 'Vitrin',
    ),
    _TabItem(
      route: '/news',
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: 'Haberler',
    ),
    _TabItem(
      route: '/support',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      label: 'Destek',
    ),
    _TabItem(
      route: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  int _indexFor(String location) {
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location == _tabs[i].route ||
          location.startsWith('${_tabs[i].route}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);

    // Aktif ders katmanı var mı? `lessonOverlayDepthProvider` sayaç
    // mantığıyla çalışır: bir sayfa push edilirken +1, pop edilirken
    // -1. Sayaç > 0 ise kullanıcı ders detayı / node editör gibi alt
    // bir ekrana geçmiş demektir — floating tab bar'ı gizleyip
    // "Devam Et" / "Çözüm" / "+70 XP" düğmelerini görünür bırakıyoruz.
    final overlayDepth = ref.watch(lessonOverlayDepthProvider);
    final hasLessonOverlay = overlayDepth > 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: hasLessonOverlay
                  ? const SizedBox.shrink(key: ValueKey('bar-hidden'))
                  : _FloatingBar(
                      key: const ValueKey('bar-visible'),
                      items: _tabs,
                      currentIndex: index,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// iOS-style floating tab bar — ekranın altından 12 px yukarıda,
/// mobil için 16 px yan marj, içeride yumuşak cam efekt + pill indicator.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.items,
    required this.currentIndex,
    super.key,
  });

  final List<_TabItem> items;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass tint: dark mode'da hafif açık overlay (cam hissi), light
    // mode'da hafif koyu overlay (okunabilir contrast).
    final glassColor = isDark
        ? scheme.surface.withValues(alpha: 0.55)
        : scheme.surface.withValues(alpha: 0.7);

    return SafeArea(
      top: false,
      // SafeArea(insets) Accounta ek, ek 0 kullanıyoruz çünkü
      // tüm platform'larda zaten ekrandan biraz yukarıda konumlandır.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 64,
              decoration: BoxDecoration(
                color: glassColor,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    // Floating shadow
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.4 : 0.16,
                    ),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.25 : 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _PillTabItem(
                        item: items[i],
                        active: i == currentIndex,
                        onTap: () => _onTap(context, items[i].route),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, String route) {
    context.go(route);
  }
}

/// Tek tab öğesi — sabit ikon boyutu, aktif/pasif renk farkı.
/// AGENTS.md gereği sade tutarlı davranış; iOS Dock stili.
class _PillTabItem extends StatelessWidget {
  const _PillTabItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final fg = active ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      label: item.label,
      selected: active,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          splashColor: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary,
                        scheme.secondary,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              active ? item.activeIcon : item.icon,
              color: fg,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}