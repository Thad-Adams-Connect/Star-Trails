import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Paints a simple space background: dark gradient and small star dots.
/// Uses deterministic "random" positions so the frame is stable.
class StarfieldPainter extends CustomPainter {
  static const int _starCount = 80;
  static const double _starMaxRadius = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Dark gradient (subtle blue-black)
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0A0A12),
        AppTheme.background,
        Color(0xFF050508),
      ],
    );
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = gradient
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Stars (deterministic positions from index)
    final rnd = Random(42);
    for (int i = 0; i < _starCount; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final t = rnd.nextDouble();
      final radius = _starMaxRadius * (0.4 + 0.6 * t);
      final alpha = 0.3 + 0.7 * t;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = AppTheme.phosphorGreen.withValues(alpha: alpha * 0.4)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        radius * 0.5,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.8)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
