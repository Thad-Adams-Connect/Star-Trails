// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'theme.dart';

/// Paints a HUD-style geometric border with soft phosphor glow for menu panels.
class HudPanelBorder extends CustomPainter {
  final double cornerLength;
  final double strokeWidth;
  final double glowRadius;

  HudPanelBorder({
    this.cornerLength = 24,
    this.strokeWidth = 2,
    this.glowRadius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      const Radius.circular(12),
    );

    // Glow layer (soft, not neon)
    final glowPaint = Paint()
      ..color = AppTheme.phosphorGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + glowRadius * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(glowRadius),
        Radius.circular(12 + glowRadius),
      ),
      glowPaint,
    );

    // Main border
    final borderPaint = Paint()
      ..color = AppTheme.phosphorGreenDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, borderPaint);

    // Inner bright edge
    final innerPaint = Paint()
      ..color = AppTheme.phosphorGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final innerR = rect.deflate(strokeWidth + 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerR, const Radius.circular(10)),
      innerPaint,
    );

    // Corner brackets (geometric HUD accent) at outer corners of rect
    final bracketPaint = Paint()
      ..color = AppTheme.phosphorGreenBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final l = cornerLength;
    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(tl.dx, tl.dy + l)
        ..lineTo(tl.dx, tl.dy)
        ..lineTo(tl.dx + l, tl.dy),
      bracketPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(tr.dx - l, tr.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(tr.dx, tr.dy + l),
      bracketPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(bl.dx, bl.dy - l)
        ..lineTo(bl.dx, bl.dy)
        ..lineTo(bl.dx + l, bl.dy),
      bracketPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(br.dx - l, br.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(br.dx, br.dy - l),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
