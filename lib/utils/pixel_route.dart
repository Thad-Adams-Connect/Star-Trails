// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'dart:math';
import 'package:flutter/material.dart';

/// PageRoute that overlays a pixelated sweep which fades away revealing the
/// new page underneath. Configurable with `columns`, `rows`, `duration` and
/// `color`.
Route<T> pixelRoute<T>(Widget page,
    {Duration duration = const Duration(milliseconds: 550),
    int columns = 40,
    int rows = 24,
    Color color = Colors.black}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return Stack(
        children: [
          child,
          // Overlay painting is driven by the animation progress.
          AnimatedBuilder(
            animation: curved,
            builder: (context, _) {
              final progress = curved.value;
              // When finished, don't draw overlay.
              if (progress >= 1.0) return const SizedBox.shrink();
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _PixelSweepPainter(
                  progress: progress,
                  columns: columns,
                  rows: rows,
                  color: color,
                ),
              );
            },
          ),
        ],
      );
    },
    transitionDuration: duration,
    reverseTransitionDuration: duration,
  );
}

class _PixelSweepPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final int columns;
  final int rows;
  final Color color;

  _PixelSweepPainter(
      {required this.progress,
      required this.columns,
      required this.rows,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final tileW = size.width / columns;
    final tileH = size.height / rows;
    final total = columns * rows;

    // Deterministic per-tile noise (stable across frames).
    double noiseFor(int index) =>
        (Random(index * 9973 + 12345).nextDouble() - 0.5) * 0.18;

    // Sweep from left-to-right/top-to-bottom linearized index.
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final index = x + y * columns;
        final tilePos = index / (total - 1);
        final offsetPos = (tilePos + noiseFor(index)).clamp(0.0, 1.0);

        // Make a narrow revealed band move with progress. Tiles to the left
        // of the band are revealed (transparent), tiles to the right remain
        // opaque; tiles in the band fade smoothly.
        const bandWidth = 0.06; // fraction of total grid
        final leftEdge = progress - bandWidth * 0.5;
        final rightEdge = progress + bandWidth * 0.5;

        double alpha;
        if (offsetPos <= leftEdge) {
          alpha = 0.0; // already revealed
        } else if (offsetPos >= rightEdge) {
          alpha = 1.0 - progress; // not yet revealed; slowly fade overall
        } else {
          // inside band -> smooth fade
          final t =
              ((offsetPos - leftEdge) / (rightEdge - leftEdge)).clamp(0.0, 1.0);
          // ease out for nicer feel
          final smooth = (1 - (1 - t) * (1 - t));
          alpha = (1.0 - smooth) * (1.0 - progress);
        }

        if (alpha <= 0) continue;

        paint.color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
        final rect = Rect.fromLTWH(x * tileW, y * tileH, tileW + 1, tileH + 1);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSweepPainter old) =>
      old.progress != progress ||
      old.columns != columns ||
      old.rows != rows ||
      old.color != color;
}
