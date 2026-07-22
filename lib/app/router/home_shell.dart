import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';

/// Bottom navigation bar yüksekliği px (çubuk + margin + safe area).
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // extendBody=false → içerik otomatik olarak bottom nav'ın
      // üstünde biter. Cam efekt için bar transparan + blur, görsel
      // olarak içeriden bağımsız.
      body: child,
      extendBody: false,
      bottomNavigationBar: _GlassBottomBar(
        items: _tabs,
        currentIndex: index,
        backgroundColor: scheme.surface.withValues(alpha: 0.78),
        onTap: (i) => context.go(_tabs[i].route),
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

/// iOS tarzı cam efektli alt bar.
class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.backgroundColor,
  });

  final List<_TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _BarItem(
                        item: items[i],
                        active: i == currentIndex,
                        onTap: () => onTap(i),
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
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textTertiary;
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: active ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                active ? item.activeIcon : item.icon,
                color: active ? Colors.white : color,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
