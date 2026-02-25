// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'theme.dart';

/// Paints a very subtle grid/circuit pattern inside HUD panels.
class GridOverlayPainter extends CustomPainter {
  final double spacing;
  final double strokeWidth;

  GridOverlayPainter({this.spacing = 32, this.strokeWidth = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.phosphorGreenDim.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
