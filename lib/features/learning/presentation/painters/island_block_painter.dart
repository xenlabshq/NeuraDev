import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/learning_island.dart';
import 'isometric_camera.dart';

/// İzometrik 3B dünyada ada platformu (rhombus blok) çizer.
/// Fancade tarzı: üst yüz + alt yüz + kenar çizgileri + gölge.
/// - Tamamlanmış ada altın çerçeveyle parlıyor.
/// - Aktif (açık ama bitmemiş) ada hafif altın glow altında.
/// - Kilitli ada: grid overlay, soğuk tonlar, kilit ikonu.
class IslandBlockPainter extends CustomPainter {
  IslandBlockPainter({
    required this.camera,
    required this.island,
    this.hovered = false,
    this.weakCount = 0,
    this.isCritical = false,
    this.averageConfidence = 1.0,
  });

  final IsometricCamera camera;
  final LearningIsland island;
  final bool hovered;
  final int weakCount;
  final bool isCritical;
  final double averageConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = camera.project(island.x, island.y, island.z);
    final s = island.size * camera.zoom;
    final color = island.color;
    final locked = !island.unlocked;
    final completed = island.allCompleted;

    // ----- SU HALKASI (dalga) -----
    // Adanın yüzen bir kaya değil, suda duran bir ada olduğu hissini
    // vermek için gölgenin altında ikinci, daha soluk ve geniş bir
    // dalga halkası çiziyoruz.
    final shadowPos = camera.project(island.x, 0, island.z);
    if (!locked) {
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowPos + Offset(0, s * 0.05),
          width: s * 2.05,
          height: s * 0.52,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ----- ZEMİN GÖLGESİ -----
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowPos + Offset(0, s * 0.05),
        width: s * 1.6,
        height: s * 0.4,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: locked ? 0.08 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ----- ALT YÜZ (yere bakan) -----
    final baseColor = locked
        ? const Color(0xFF3A3550) // kilitli ada için soğuk koyu
        : color;
    final basePath = Path()
      ..moveTo(pos.dx, pos.dy - s * 0.1)
      ..lineTo(pos.dx + s * 0.7, pos.dy + s * 0.25)
      ..lineTo(pos.dx, pos.dy + s * 0.6)
      ..lineTo(pos.dx - s * 0.7, pos.dy + s * 0.25)
      ..close();
    canvas.drawPath(
      basePath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor,
                Color.lerp(baseColor, Colors.black, 0.55)!,
              ],
            ).createShader(
              Rect.fromCenter(
                center: pos,
                width: s * 1.4,
                height: s * 0.7,
              ),
            ),
    );

    // ----- ÜST YÜZ (yukarı bakan) -----
    final topColor = locked
        ? const Color(0xFF5C5778) // kilitli ada: grimsi-mor
        : Color.lerp(color, Colors.white, 0.3)!;
    final topPath = Path()
      ..moveTo(pos.dx, pos.dy - s * 0.6)
      ..lineTo(pos.dx + s * 0.7, pos.dy - s * 0.25)
      ..lineTo(pos.dx, pos.dy + s * 0.1)
      ..lineTo(pos.dx - s * 0.7, pos.dy - s * 0.25)
      ..close();

    if (locked) {
      // Kilitli ada: düz renk, hafif grid overlay
      canvas.drawPath(
        topPath,
        Paint()..color = topColor,
      );
    } else {
      canvas.drawPath(
        topPath,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, color],
              ).createShader(
                Rect.fromCenter(
                  center: pos,
                  width: s * 1.4,
                  height: s * 0.6,
                ),
              ),
      );
    }

    // ----- ZEMİN DOKUSU (kum/çim benekleri) -----
    // Düz tek renkli üst yüzü kırmak için birkaç küçük, sabit (deterministik
    // — her frame'de aynı yerde) doku noktası serpiştiriyoruz. Ada
    // id'sinden türetilen bir tohum kullanılıyor ki harita her yeniden
    // çizildiğinde noktalar titremesin/kaymasın.
    if (!locked) {
      final rng = math.Random(island.id.hashCode);
      final texturePaint = Paint()
        ..color = Color.lerp(topColor, Colors.black, 0.25)!.withValues(
          alpha: 0.35,
        );
      for (var i = 0; i < 7; i++) {
        final tx = pos.dx + (rng.nextDouble() * 2 - 1) * s * 0.55;
        final tyBase = pos.dy - s * 0.25;
        final ty = tyBase + (rng.nextDouble() * 2 - 1) * s * 0.28;
        canvas.drawCircle(Offset(tx, ty), s * 0.02 + rng.nextDouble() * s * 0.015, texturePaint);
      }
    }

    // ----- CAM/PARLAKLIK VURGUSU (üst yüz) -----
    // Profesyonel/cilalı bir görünüm için üst yüzün sol-üst köşesine
    // (varsayılan ışık kaynağı yönü) yumuşak, oval bir parlaklık lekesi
    // ekliyoruz — düz gradyanı kırıp yüzeye "cam gibi" bir derinlik verir.
    if (!locked) {
      canvas.save();
      canvas.clipPath(topPath);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx - s * 0.28, pos.dy - s * 0.42),
          width: s * 0.55,
          height: s * 0.22,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.restore();
    }

    // ----- KİLİTLİ ADA: GRİD OVERLAY -----
    if (locked) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.0;
      // Üst yüz üzerinde diyagonal çapraz çizgiler (demir parmaklık hissi)
      final cx = pos.dx;
      final cy = pos.dy - s * 0.225; // üst yüz merkezi
      const step = 14.0;
      for (var i = -6; i <= 6; i++) {
        final off = i * step;
        canvas.drawLine(
          Offset(cx + off, cy - s * 0.35),
          Offset(cx + off * 0.3, cy + s * 0.35),
          gridPaint,
        );
      }
    }

    // ----- IŞIK KENARI (rim-light bevel) -----
    // Sol-üst kenar (batı → kuzey köşesi) ışığa bakan kenar gibi
    // parlatılıyor — düz tek renkli kontürden daha cilalı/3B bir
    // "bevel" hissi verir.
    if (!locked) {
      canvas.drawLine(
        Offset(pos.dx - s * 0.7, pos.dy - s * 0.25),
        Offset(pos.dx, pos.dy - s * 0.6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // ----- KENAR ÇİZİGİLERİ -----
    final edgePaint = Paint()
      ..color = completed
          ? const Color(0xFFFFC145).withValues(alpha: 0.7)
          : (locked
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = completed ? 2.5 : 1.5;
    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(basePath, edgePaint);

    // ----- ZAYIF ADA UYARISI -----
    // weakCount > 0 ise kırmızı kenarlık + dikkat üçgeni göster.
    if (weakCount > 0 && !locked) {
      // Kırmızı kenarlık glow (kritik ise daha yoğun)
      final alertColor = isCritical
          ? const Color(0xFFEF4444)
          : const Color(0xFFF59E0B);
      final alertAlpha = isCritical ? 0.85 : 0.55;
      canvas.drawPath(
        topPath,
        Paint()
          ..color = alertColor.withValues(alpha: alertAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCritical ? 4.0 : 2.5
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            isCritical ? 6 : 3,
          ),
      );

      // Kritik ada için ekstra "!" badge sağ üstte
      if (isCritical) {
        final tpBadge = TextPainter(
          text: TextSpan(
            text: '⚠️',
            style: TextStyle(fontSize: s * 0.35),
          ),
          textDirection: TextDirection.ltr,
        );
        tpBadge.layout();
        tpBadge.paint(
          canvas,
          Offset(
            pos.dx + s * 0.5,
            pos.dy - s * 0.7,
          ),
        );
      }

      // weakCount göstergesi (küçük sayaç)
      if (weakCount > 0) {
        final tpCount = TextPainter(
          text: TextSpan(
            text: '$weakCount zayıf',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: alertColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tpCount.layout();
        tpCount.paint(
          canvas,
          Offset(
            pos.dx - tpCount.width / 2,
            pos.dy + s * 0.35,
          ),
        );
      }
    }

    // ----- HOVER SCALE GÖLGESİ -----
    if (hovered && !locked) {
      canvas.drawPath(
        topPath,
        Paint()
          ..color = const Color(0xFFFFC145).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // ----- EMOJİ -----
    final tp = TextPainter(
      text: TextSpan(
        text: locked ? '🔒' : island.emoji,
        style: TextStyle(
          fontSize: s * 0.55,
          color: locked ? Colors.white.withValues(alpha: 0.7) : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(pos.dx - tp.width / 2, pos.dy - s * 0.45 - tp.height / 2),
    );

    // ----- TAMAMLANMIŞ ALTIN ÇERÇEVE -----
    if (completed) {
      final goldPaint = Paint()
        ..color = const Color(0xFFFFC145)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawPath(topPath, goldPaint);
      // 5 köşe yıldızı
      final star = TextPainter(
        text: const TextSpan(
          text: '⭐',
          style: TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );
      star.layout();
      star.paint(canvas, Offset(pos.dx - star.width / 2, pos.dy - s * 0.8));
    }

    // ----- TAMAMLANMA İLERLEME BAR + RAKAMSAL ROZET -----
    if (!locked && island.totalNodes > 0 && !completed) {
      final progress = island.completedNodes / island.totalNodes;
      final barWidth = s * 1.0;
      final barHeight = 6.0;
      final barLeft = pos.dx - barWidth / 2;
      final barTop = pos.dy + s * 0.18;
      // Bara hafif bir gölge — zemine "oturmuş" hissi verir.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop + 1.5, barWidth, barHeight),
          const Radius.circular(3),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      // background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
      // fill
      if (progress > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barLeft, barTop, barWidth * progress, barHeight),
            const Radius.circular(3),
          ),
          Paint()
            ..shader = LinearGradient(
              colors: const [Color(0xFF66BB6A), Color(0xFF3FA047)],
            ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight)),
        );
      }
      // Küçük "x/y" rozeti — barın hemen altında, koyu kapsül içinde.
      final badgeText = TextPainter(
        text: TextSpan(
          text: '${island.completedNodes}/${island.totalNodes}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      badgeText.layout();
      final badgeWidth = badgeText.width + 10;
      const badgeHeight = 14.0;
      final badgeTop = barTop + barHeight + 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            pos.dx - badgeWidth / 2,
            badgeTop,
            badgeWidth,
            badgeHeight,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.4),
      );
      badgeText.paint(
        canvas,
        Offset(pos.dx - badgeText.width / 2, badgeTop + 2.5),
      );
    }

    // ----- AKTİF PARILTI (sadece açık + bitmemiş) -----
    if (!locked && !completed) {
      canvas.drawCircle(
        pos,
        s * 0.65,
        Paint()
          ..color = const Color(0xFFFFC145).withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant IslandBlockPainter old) =>
      old.camera != camera ||
      old.island != island ||
      old.hovered != hovered ||
      old.weakCount != weakCount ||
      old.isCritical != isCritical ||
      old.averageConfidence != averageConfidence;
}

/// Adalar arası ahşap yol çizgisi çizer.
class IslandPathPainter extends CustomPainter {
  IslandPathPainter({
    required this.camera,
    required this.from,
    required this.to,
    required this.active,
  });

  final IsometricCamera camera;
  final Offset from; // izometrik ekran koordinatı
  final Offset to;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    // Zemine oturan bir gölge — köprünün havada asılı değil, adalar
    // arasında gerçekten döşenmiş gibi görünmesini sağlar.
    canvas.drawLine(
      from + const Offset(0, 2),
      to + const Offset(0, 2),
      Paint()
        ..color = Colors.black.withValues(alpha: active ? 0.28 : 0.14)
        ..strokeWidth = active ? 6 : 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final paint = Paint()
      ..shader = active
          ? const LinearGradient(
              colors: [Color(0xFFE0A458), Color(0xFFCD853F)],
            ).createShader(Rect.fromPoints(from, to))
          : null
      ..color = active ? const Color(0xFFCD853F) : Colors.grey.shade400
      ..strokeWidth = active ? 4 : 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nx = -dy / dist * (active ? 8 : 6);
    final ny = dx / dist * (active ? 8 : 6);
    final plankCount = (dist / 16).clamp(2, 6).round();
    for (var i = 1; i < plankCount; i++) {
      final t = i / plankCount;
      final pos = Offset(from.dx + dx * t, from.dy + dy * t);
      canvas.drawLine(
        Offset(pos.dx + nx, pos.dy + ny),
        Offset(pos.dx - nx, pos.dy - ny),
        Paint()
          ..color = active
              ? const Color(0xFF8B4513)
              : Colors.grey.shade500
          ..strokeWidth = active ? 3.5 : 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IslandPathPainter old) =>
      old.camera != camera ||
      old.from != from ||
      old.to != to ||
      old.active != active;
}
