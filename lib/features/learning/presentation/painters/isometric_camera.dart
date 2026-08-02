import 'dart:math' as math;
import 'package:flutter/material.dart';

/// İzometrik kamera: 3D (x, y, z) → 2D ekran koordinatına.
/// Standart izometrik açı: x ekseni 30° sağ-aşağı, z ekseni 30° sol-aşağı.
///
/// F-01: immutable — `withPan` / `withZoom` / `withViewportSize` ile yeni
/// instance döner, eski camera instance'ları referans olarak korunur.
/// F-16: cos/sin her `project()` çağrısında yeniden hesaplanmaz;
/// constructor'da bir kez cache'lenir.
class IsometricCamera {
  IsometricCamera({
    required this.viewportSize,
    this.center = Offset.zero,
    this.zoom = 1.0,
    this.angle = 0.5,
  })  : _cosA = math.cos(angle),
        _sinA = math.sin(angle);

  final Size viewportSize;
  final Offset center;
  final double zoom;
  final double angle;

  // F-16: Açıya göre bir kez hesaplanan trigonometri cache'i.
  final double _cosA;
  final double _sinA;

  Offset project(double x, double y, double z) {
    final screenX = (x - z) * _cosA;
    final screenY = (x + z) * _sinA - y;
    final cx = viewportSize.width / 2 + center.dx;
    final cy = viewportSize.height / 2 + center.dy;
    return Offset(cx + screenX * zoom, cy + screenY * zoom);
  }

  /// Pan uygulayarak yeni kamera döndürür.
  IsometricCamera withPan(Offset delta) => IsometricCamera(
        viewportSize: viewportSize,
        center: center + delta,
        zoom: zoom,
        angle: angle,
      );

  /// Zoom uygulayarak yeni kamera döndürür.
  IsometricCamera withZoom(double f) => IsometricCamera(
        viewportSize: viewportSize,
        center: center,
        zoom: (zoom * f).clamp(0.6, 2.0),
        angle: angle,
      );

  /// Viewport değişmiş hali.
  IsometricCamera withViewportSize(Size newSize) => IsometricCamera(
        viewportSize: newSize,
        center: center,
        zoom: zoom,
        angle: angle,
      );
}