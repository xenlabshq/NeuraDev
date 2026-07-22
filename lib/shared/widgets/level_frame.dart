import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/models/user_level.dart';

/// Seviyeye göre özel çerçeve — Bronze/Silver/Gold/Diamond/Master.
class LevelFrame extends StatelessWidget {
  const LevelFrame({
    required this.child,
    required this.tier,
    required this.level,
    this.size = 96,
    super.key,
  });

  final Widget child;
  final UserTier tier;
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(
        tier: tier,
        level: level,
        strokeWidth: size > 80 ? 4 : 3,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({
    required this.tier,
    required this.level,
    required this.strokeWidth,
  });

  final UserTier tier;
  final int level;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          tier.gradient.first.withValues(alpha: 0.5),
          tier.gradient.last.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Tier-specific frame
    switch (tier) {
      case UserTier.bronze:
        _paintBronze(canvas, center, radius);
      case UserTier.silver:
        _paintSilver(canvas, center, radius);
      case UserTier.gold:
        _paintGold(canvas, center, radius);
      case UserTier.diamond:
        _paintDiamond(canvas, center, radius);
      case UserTier.master:
        _paintMaster(canvas, center, radius);
    }

    // Star decorations for high tiers
    if (tier.index >= UserTier.gold.index) {
      _paintStars(canvas, center, radius);
    }
  }

  void _paintBronze(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          ...tier.gradient,
          ...tier.gradient.reversed,
          tier.gradient.first,
        ],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paint);
  }

  void _paintSilver(Canvas canvas, Offset center, double radius) {
    // Double ring
    final outer = Paint()
      ..shader = LinearGradient(
        colors: tier.gradient,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, outer);

    final inner = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 5, inner);
  }

  void _paintGold(Canvas canvas, Offset center, double radius) {
    // Outer ring
    final outer = Paint()
      ..shader = SweepGradient(
        colors: [
          ...tier.gradient,
          Colors.white,
          ...tier.gradient,
        ],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1;
    canvas.drawCircle(center, radius, outer);

    // Diamond gems
    final gem = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (var i = 0; i < 4; i++) {
      final angle = (math.pi * 2 / 4) * i - math.pi / 4;
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(p, 2.5, gem);
    }
  }

  void _paintDiamond(Canvas canvas, Offset center, double radius) {
    // Animated-looking prismatic outer ring
    final outer = Paint()
      ..shader = SweepGradient(
        colors: [
          tier.gradient.first,
          Colors.white,
          tier.gradient.last,
          Colors.white,
          tier.gradient.first,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5;
    canvas.drawCircle(center, radius, outer);

    // 6 facet accents
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi * 2 / 6) * i;
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final facet = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 3, facet);
    }

    // Sparkle lines
    final spark = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i + math.pi / 8;
      final r1 = radius + 4;
      final r2 = radius + 8;
      canvas.drawLine(
        Offset(
          center.dx + r1 * math.cos(angle),
          center.dy + r1 * math.sin(angle),
        ),
        Offset(
          center.dx + r2 * math.cos(angle),
          center.dy + r2 * math.sin(angle),
        ),
        spark,
      );
    }
  }

  void _paintMaster(Canvas canvas, Offset center, double radius) {
    // Double prismatic ring
    final outer = Paint()
      ..shader = SweepGradient(
        colors: [
          ...tier.gradient,
          AppColors.gold,
          ...tier.gradient,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2;
    canvas.drawCircle(center, radius, outer);

    final mid = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 4, mid);

    // Crown-like notches
    for (var i = 0; i < 12; i++) {
      final angle = (math.pi * 2 / 12) * i;
      final p1 = Offset(
        center.dx + (radius - 1) * math.cos(angle),
        center.dy + (radius - 1) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 5) * math.cos(angle),
        center.dy + (radius + 5) * math.sin(angle),
      );
      final notch = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, notch);
    }
  }

  void _paintStars(Canvas canvas, Offset center, double radius) {
    final star = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 0; i < 3; i++) {
      final angle = (math.pi * 2 / 3) * i + math.pi / 6;
      final p = Offset(
        center.dx + (radius + 14) * math.cos(angle),
        center.dy + (radius + 14) * math.sin(angle),
      );
      canvas.drawCircle(p, 1.5, star);
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.tier != tier || old.level != level;
}
