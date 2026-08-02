import 'package:flutter/widgets.dart';

/// Responsive helpers — tek bir design system üzerinden tüm ekran boyutlarına
/// uyum sağlayan yardımcılar.
class LayoutHelper {
  LayoutHelper._();

  /// Tablet alt-bar breakpoint: < 600 px telefon, ≥ 600 tablet+.
  /// Bileşenler farklı label politikası kullanır.
  static const double kTabletBreakpoint = 600;

  /// Geniş ekran breakpoint: tablet üstü.
  static const double kDesktopBreakpoint = 1024;

  /// Çok küçük ekran breakpoint: < 360 px (dar telefonlar için).
  static const double kCompactBreakpoint = 360;

  /// Ekran genişliği 600'den büyükse tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= kTabletBreakpoint;

  /// Ekran genişliği 1024'den büyükse desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= kDesktopBreakpoint;

  /// Çok küçük ekran (< 360 px): kompakt layout için.
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < kCompactBreakpoint;

  /// Geniş ekran — tablet+ (>600px): label her zaman gösterilir.
  static bool isExpandedLayout(BuildContext context) =>
      MediaQuery.of(context).size.width >= kTabletBreakpoint;

  /// Ekran kısa mı (küçük mobil yatay)?
  static bool isShort(BuildContext context) =>
      MediaQuery.of(context).size.height < 600;

  /// Yatay mı?
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Genişliğe göre grid sayısı.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1280) return 6;
    if (w >= 1024) return 5;
    if (w >= 768) return 4;
    if (w >= 560) return 3;
    if (w >= 380) return 2;
    return 2;
  }

  /// Genişliğe göre container max-width (okunabilirlik için).
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 1200;
    if (w >= 1024) return 900;
    if (w >= 768) return 720;
    return double.infinity;
  }

  /// Yatay padding (responsive).
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1024) return 32;
    if (w >= 768) return 28;
    if (w >= 600) return 24;
    return 20;
  }

  /// Genişliğe göre font size scaling (1.0 = baz).
  static double scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1400) return 1.15;
    if (w >= 1024) return 1.08;
    if (w >= 600) return 1.0;
    if (w >= 380) return 0.95;
    return 0.9;
  }

  /// Safe area padding + status bar.
  static EdgeInsets screenPadding(BuildContext context) {
    final mq = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mq.padding.top,
      bottom: mq.padding.bottom,
      left: mq.padding.left,
      right: mq.padding.right,
    );
  }

  /// Bottom navigation bar yüksekliği (cam efekt dahil).
  /// SafeArea.bottom + 12 padding + 60 bar + 12 padding.
  static double bottomBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + 84;
}

/// Bottom navigation bar yüksekliği kadar alt boşluk bırakan wrapper.
/// İçerik bar'ın altına saklanmasın.
class BottomBarSafeArea extends StatelessWidget {
  const BottomBarSafeArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.padding.bottom + 84),
      child: child,
    );
  }
}

/// Content max-width wrapper — büyük ekranlarda içeriği ortalar.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    this.maxWidth = 1200,
    this.padding = 20,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: child,
        ),
      ),
    );
  }
}
