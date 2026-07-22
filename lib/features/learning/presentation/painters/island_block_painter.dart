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
  });

  final IsometricCamera camera;
  final LearningIsland island;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = camera.project(island.x, island.y, island.z);
    final s = island.size * camera.zoom;
    final color = island.color;
    final locked = !island.unlocked;
    final completed = island.allCompleted;

    // ----- ZEMİN GÖLGESİ -----
    final shadowPos = camera.project(island.x, 0, island.z);
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
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.55)!,
          ],
        ).createShader(Rect.fromCenter(
          center: pos,
          width: s * 1.4,
          height: s * 0.7,
        )),
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
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topColor, color],
          ).createShader(Rect.fromCenter(
            center: pos,
            width: s * 1.4,
            height: s * 0.6,
          )),
      );
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

    // ----- TAMAMLANMA İLERLEME BAR -----
    if (!locked && island.totalNodes > 0 && !completed) {
      final progress = island.completedNodes / island.totalNodes;
      final barWidth = s * 1.0;
      final barHeight = 6.0;
      final barLeft = pos.dx - barWidth / 2;
      final barTop = pos.dy + s * 0.18;
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
          Paint()..color = const Color(0xFF66BB6A),
        );
      }
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
      old.hovered != hovered;
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
    final paint = Paint()
      ..color = active
          ? const Color(0xFFCD853F)
          : Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nx = -dy / dist * 7;
    final ny = dx / dist * 7;
    for (var i = 1; i < 4; i++) {
      final t = i / 4;
      final pos = Offset(from.dx + dx * t, from.dy + dy * t);
      canvas.drawLine(
        Offset(pos.dx + nx, pos.dy + ny),
        Offset(pos.dx - nx, pos.dy - ny),
        Paint()
          ..color = const Color(0xFF8B4513)
          ..strokeWidth = 4,
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