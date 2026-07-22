import 'package:flutter/widgets.dart';

/// Ekran boyutuna göre otomatik ölçeklenen değerler.
///
/// Tüm sayfalarda sabit `fontSize: 15`, `width: 72` gibi değerler yerine
/// `context.t(15)` veya `context.s(72)` kullanın. Bu extension MediaQuery
/// üzerinden ekran boyutuna göre değerleri oranlar.
///
/// **Neden?** Küçük ekranda 15px font sığmaz, büyük ekranda çok küçük kalır.
/// Sabit değerler yerine oranlı değerler kullanmak hem taşmayı önler hem de
/// kullanıcı deneyimini tüm cihazlarda tutarlı kılar.
extension ResponsiveContext on BuildContext {
  /// Ekran genişliğine göre oranlanmış **boyut** (genişlik, yükseklik, padding).
  ///
  /// Referans genişlik 360 (en küçük mobil), scale 1.0.
  /// 720 genişlikte scale ~1.5, 1024'te ~1.7.
  double s(double base) {
    final width = MediaQuery.sizeOf(this).width;
    final scale = (width / 360).clamp(0.85, 1.6);
    return base * scale;
  }

  /// Ekran genişliğine göre oranlanmış **font boyutu**.
  ///
  /// TextScaleFactor uygulanmış hali. Sistem font ölçeğini de dikkate alır.
  double t(double base) {
    final mq = MediaQuery.of(this);
    final widthScale = (MediaQuery.sizeOf(this).width / 360).clamp(0.85, 1.6);
    final textScale = mq.textScaler.scale(1.0);
    return base * widthScale * textScale;
  }

  /// Kısa kenarı clamp'li oranlama (kare ekranlar için).
  double sMin(double base) {
    final mq = MediaQuery.sizeOf(this);
    final minSide = mq.width < mq.height ? mq.width : mq.height;
    final scale = (minSide / 360).clamp(0.85, 1.4);
    return base * scale;
  }
}