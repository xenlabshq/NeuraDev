import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/utils/layout_helper.dart';

/// Bottom navigation bar için ayrılan toplam yükseklik
/// (margin + bar içerik + alt safe area).
const double kBottomBarHeight = 84;

class HomeShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);

    return Scaffold(
      // extendBody=true → child barın altına uzanır (orada
      // padding ile biz korumaya alıyoruz). Stack'in konumlandırması
      // böylece bar yüzer halde görünür.
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingBar(
              items: _tabs,
              currentIndex: index,
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

/// Tek tab öğesi — aktif ise yumuşak iOS pill + label görünür,
/// değilse sadece icon.
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

    // iOS Dock stili: alt barda hiçbir zaman yazı görünmez, sadece
    // ikonlar. Aktif durum pill rengi ile (mor-pembe gradient) ifade
    // edilir. AGENTS.md gereği ekran boyutundan bağımsız tutarlı.
    final showLabel = false;

    // Aktif renk: primary. Pasif renk: onSurfaceVariant.
    final fg = active ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      label: item.label,
      selected: active,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Pill tıklamasını yumuşat.
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          splashColor: scheme.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            // Aktifken geniş, pasifte dar (veya expanded'da sabit).
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 18 : 10,
              vertical: showLabel ? 10 : 8,
            ),
            decoration: BoxDecoration(
              // Pill — ana renklerde yumuşak gradient.
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
            // Row(ikon + label yanda) — eski istenen layout.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // İkon
                Icon(
                  active ? item.activeIcon : item.icon,
                  color: fg,
                  size: 24,
                ),
                // Label — showLabel ise göster.
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: SizedBox(
                    width: showLabel ? null : 0,
                    height: showLabel ? null : 0,
                    child: Padding(
                      padding: EdgeInsets.only(left: showLabel ? 8 : 0),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}