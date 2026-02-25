// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';

/// Central theme for Star Trails. CRT terminal aesthetic with phosphor green.
/// All UI should use these constants instead of hard-coded colors.
class AppTheme {
  AppTheme._();

  // --- Phosphor green (darker, softer – classic CRT terminal)
  static const Color phosphorGreen = Color(0xFF00AA55);
  static const Color phosphorGreenBright = Color(0xFF00CC66);
  static const Color phosphorGreenDim = Color(0xFF008844);

  // --- Backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  // --- UI
  static const Color divider = phosphorGreenDim;
  static const Color border = phosphorGreenDim;
  static const Color error = Color(0xFFCC4444);

  /// Soft glow for terminal text (not neon, not blurry).
  static List<Shadow> get terminalTextGlow => [
        Shadow(
          color: phosphorGreen.withValues(alpha: 0.6),
          blurRadius: 6,
          offset: Offset.zero,
        ),
        Shadow(
          color: phosphorGreen.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: Offset.zero,
        ),
      ];

  static TextStyle get terminalTitle => const TextStyle(
        color: phosphorGreenBright,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ).copyWith(shadows: terminalTextGlow);

  static TextStyle get terminalSubtitle => const TextStyle(
        color: phosphorGreenDim,
        fontSize: 16,
        fontFamily: 'monospace',
      );

  static TextStyle get terminalBody => const TextStyle(
        color: phosphorGreenBright,
        fontSize: 14,
        fontFamily: 'monospace',
        height: 1.4,
      ).copyWith(shadows: terminalTextGlow);

  static TextStyle get terminalLabel => const TextStyle(
        color: phosphorGreen,
        fontSize: 10,
        fontFamily: 'monospace',
      );

  static TextStyle get terminalPrompt => const TextStyle(
        color: phosphorGreenBright,
        fontSize: 18,
        fontFamily: 'monospace',
      ).copyWith(shadows: terminalTextGlow);

  static TextStyle get appBarTitle => const TextStyle(
        fontFamily: 'monospace',
        color: phosphorGreenBright,
        fontSize: 18,
      ).copyWith(shadows: terminalTextGlow);
}
