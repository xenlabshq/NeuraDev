import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/learning_island.dart';
import 'isometric_camera.dart';

/// İzometrik 3B dünyada bir öğrenme platformu (rhombus blok) çizer.
/// Fütüristik/tech tasarım dili: holografik enerji halkası, cam/HUD
/// parlaklığı, devre izi dokusu, köşe hedefleme parantezleri.
/// - Tamamlanmış platform enerji rengiyle parlıyor.
/// - Aktif (açık ama bitmemiş) platform hafif bir güç alanı altında.
/// - Kilitli platform: grid overlay, soğuk tonlar, kilit ikonu.
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

    // ----- ENERJİ HALKASI -----
    // Platformun suda değil, bir güç alanı üzerinde yüzdüğü hissi için
    // altında ikinci, geniş ve soluk bir holografik halka.
    final shadowPos = camera.project(island.x, 0, island.z);
    if (!locked) {
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowPos + Offset(0, s * 0.05),
          width: s * 2.05,
          height: s * 0.52,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowPos + Offset(0, s * 0.05),
          width: s * 1.7,
          height: s * 0.42,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }

    // ----- ZEMİN GÖLGESİ (enerji alanı) -----
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowPos + Offset(0, s * 0.05),
        width: s * 1.6,
        height: s * 0.4,
      ),
      Paint()
        ..color = locked
            ? Colors.black.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ----- ALT YÜZ (yere bakan) -----
    final baseColor = locked
        ? const Color(0xFF272238) // kilitli platform için soğuk koyu
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
                Color.lerp(baseColor, Colors.black, 0.6)!,
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
        ? const Color(0xFF423C5E) // kilitli platform: grimsi-mor
        : Color.lerp(color, Colors.white, 0.25)!;
    final topPath = Path()
      ..moveTo(pos.dx, pos.dy - s * 0.6)
      ..lineTo(pos.dx + s * 0.7, pos.dy - s * 0.25)
      ..lineTo(pos.dx, pos.dy + s * 0.1)
      ..lineTo(pos.dx - s * 0.7, pos.dy - s * 0.25)
      ..close();
    // topPath'in dört köşesi — HUD köşe parantezleri ve devre dokusu için.
    final corners = [
      Offset(pos.dx, pos.dy - s * 0.6), // kuzey
      Offset(pos.dx + s * 0.7, pos.dy - s * 0.25), // doğu
      Offset(pos.dx, pos.dy + s * 0.1), // güney
      Offset(pos.dx - s * 0.7, pos.dy - s * 0.25), // batı
    ];

    if (locked) {
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

    // ----- DEVRE İZİ DOKUSU (circuit traces) -----
    // Düz tek renkli üst yüzü kırmak için birkaç küçük, sabit
    // (deterministik) devre kartı izi çiziyoruz — kum/çim yerine
    // mikroçip yüzeyi hissi. Ada id'sinden türetilen bir tohum
    // kullanılıyor ki harita her yeniden çizildiğinde kaymasın.
    if (!locked) {
      final rng = math.Random(island.id.hashCode);
      final tracePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      final nodePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.32);
      for (var i = 0; i < 5; i++) {
        final ox = pos.dx + (rng.nextDouble() * 2 - 1) * s * 0.5;
        final oy = pos.dy - s * 0.25 + (rng.nextDouble() * 2 - 1) * s * 0.26;
        final legLen = s * (0.06 + rng.nextDouble() * 0.06);
        final horizontal = rng.nextBool();
        final end = horizontal
            ? Offset(ox + legLen, oy)
            : Offset(ox, oy + legLen * 0.6);
        canvas.drawLine(Offset(ox, oy), end, tracePaint);
        canvas.drawCircle(Offset(ox, oy), 1.4, nodePaint);
        canvas.drawCircle(end, 1.4, nodePaint);
      }
    }

    // ----- CAM/HUD PARLAKLIĞI (üst yüz) -----
    // Cilalı/holografik bir yüzey hissi için sol-üst köşeye yumuşak,
    // oval bir parlaklık lekesi — düz gradyanı kırar.
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
          ..color = Colors.white.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.restore();
    }

    // ----- KİLİTLİ PLATFORM: GRİD OVERLAY -----
    if (locked) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.0;
      final cx = pos.dx;
      final cy = pos.dy - s * 0.225;
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
    if (!locked) {
      canvas.drawLine(
        Offset(pos.dx - s * 0.7, pos.dy - s * 0.25),
        Offset(pos.dx, pos.dy - s * 0.6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // ----- KENAR ÇİZİGİLERİ -----
    final edgePaint = Paint()
      ..color = completed
          ? const Color(0xFF22D3EE).withValues(alpha: 0.75)
          : (locked
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = completed ? 2.5 : 1.5;
    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(basePath, edgePaint);

    // ----- HUD KÖŞE PARANTEZLERİ -----
    // Her köşede, birleşen iki kenar boyunca kısa çizgiler — kamera
    // vizörü / hedefleme reticle görünümü. Bu tek başına "ada" hissini
    // "tech platform/data node" hissine çeviren en belirgin dokunuş.
    if (!locked) {
      final bracketPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < corners.length; i++) {
        final v = corners[i];
        final a = corners[(i - 1 + corners.length) % corners.length];
        final b = corners[(i + 1) % corners.length];
        canvas.drawLine(v, Offset.lerp(v, a, 0.22)!, bracketPaint);
        canvas.drawLine(v, Offset.lerp(v, b, 0.22)!, bracketPaint);
      }
    }

    // ----- ZAYIF DÜĞÜM UYARISI -----
    if (weakCount > 0 && !locked) {
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

    // ----- HOVER GÜÇ ALANI -----
    if (hovered && !locked) {
      canvas.drawPath(
        topPath,
        Paint()
          ..color = color.withValues(alpha: 0.4)
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

    // ----- TAMAMLANMIŞ ENERJİ ÇERÇEVESİ -----
    if (completed) {
      final energyPaint = Paint()
        ..color = const Color(0xFF22D3EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawPath(topPath, energyPaint);
      final spark = TextPainter(
        text: const TextSpan(
          text: '⚡',
          style: TextStyle(fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );
      spark.layout();
      spark.paint(canvas, Offset(pos.dx - spark.width / 2, pos.dy - s * 0.8));
    }

    // ----- İLERLEME BARI + RAKAMSAL ROZET -----
    if (!locked && island.totalNodes > 0 && !completed) {
      final progress = island.completedNodes / island.totalNodes;
      final barWidth = s * 1.0;
      final barHeight = 6.0;
      final barLeft = pos.dx - barWidth / 2;
      final barTop = pos.dy + s * 0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop + 1.5, barWidth, barHeight),
          const Radius.circular(3),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
      if (progress > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barLeft, barTop, barWidth * progress, barHeight),
            const Radius.circular(3),
          ),
          Paint()
            ..shader = LinearGradient(
              colors: const [Color(0xFF22D3EE), Color(0xFF0891B2)],
            ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight)),
        );
      }
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

    // ----- AKTİF GÜÇ ALANI (sadece açık + bitmemiş) -----
    if (!locked && !completed) {
      canvas.drawCircle(
        pos,
        s * 0.65,
        Paint()
          ..color = color.withValues(alpha: 0.22)
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

/// Platformlar arası holografik enerji hattı çizer.
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
    // Zemine oturan bir gölge/glow — hattın havada asılı değil, gerçekten
    // döşenmiş gibi görünmesini sağlar.
    canvas.drawLine(
      from + const Offset(0, 2),
      to + const Offset(0, 2),
      Paint()
        ..color = (active ? const Color(0xFF22D3EE) : Colors.grey.shade600)
            .withValues(alpha: active ? 0.35 : 0.14)
        ..strokeWidth = active ? 7 : 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final paint = Paint()
      ..shader = active
          ? const LinearGradient(
              colors: [Color(0xFF67E8F9), Color(0xFF0891B2)],
            ).createShader(Rect.fromPoints(from, to))
          : null
      ..color = active ? const Color(0xFF0891B2) : Colors.grey.shade500
      ..strokeWidth = active ? 3 : 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    // Hat üzerinde eşit aralıklı, parlayan "enerji düğümleri" — ahşap
    // köprü tahtaları yerine devre/veri akışı hissi.
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nodeCount = (dist / 20).clamp(2, 7).round();
    final nodePaint = Paint()
      ..color = active
          ? const Color(0xFFE0F7FA)
          : Colors.grey.shade400.withValues(alpha: 0.6);
    for (var i = 1; i < nodeCount; i++) {
      final t = i / nodeCount;
      final p = Offset(from.dx + dx * t, from.dy + dy * t);
      if (active) {
        canvas.drawCircle(
          p,
          3.2,
          Paint()
            ..color = const Color(0xFF22D3EE).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(p, active ? 1.8 : 1.3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant IslandPathPainter old) =>
      old.camera != camera ||
      old.from != from ||
      old.to != to ||
      old.active != active;
}
