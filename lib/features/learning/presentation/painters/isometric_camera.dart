import 'dart:math' as math;
import 'package:flutter/material.dart';

/// İzometrik kamera: 3D (x, y, z) → 2D ekran koordinatına.
/// Standart izometrik açı: x ekseni 30° sağ-aşağı, z ekseni 30° sol-aşağı.
class IsometricCamera {
  IsometricCamera({
    required this.viewportSize,
    this.center = Offset.zero,
    this.zoom = 1.0,
    this.angle = 0.5,
  });

  final Size viewportSize;
  Offset center;
  double zoom;
  final double angle;

  Offset project(double x, double y, double z) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final screenX = (x - z) * cosA;
    final screenY = (x + z) * sinA - y;
    final cx = viewportSize.width / 2 + center.dx;
    final cy = viewportSize.height / 2 + center.dy;
    return Offset(cx + screenX * zoom, cy + screenY * zoom);
  }

  void pan(Offset delta) => center += delta;
  void zoomBy(double f) => zoom = (zoom * f).clamp(0.6, 2.0);
}