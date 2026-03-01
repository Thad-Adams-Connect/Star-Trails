// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import '../utils/hud_panel_border.dart';
import '../utils/starfield_painter.dart';
import '../utils/grid_overlay_painter.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'teacher_mode_screen.dart';
import 'player_identity_screen.dart';
import '../utils/pixel_route.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasSave = false;
  bool _saveCorrupted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSave();
    });
  }

  Future<void> _checkSave() async {
    if (!mounted) return;
    final provider = context.read<GameProvider>();
    final loaded = await provider.loadGame();
    if (!mounted) return;
    setState(() {
      _hasSave = loaded;
      _saveCorrupted = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.phosphorGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Panel background (semi-transparent, rounded)
                      Container(
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: GridOverlayPainter(spacing: 36),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 40,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'STAR TRAILS',
                                    style: AppTheme.terminalTitle.copyWith(
                                      fontSize: 40,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'v1.0.0',
                                    style: AppTheme.terminalSubtitle,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  if (_saveCorrupted)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        'Save file corrupted. Starting new game.',
                                        style: TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  _HudMenuButton(
                                    label: 'NEW GAME',
                                    onPressed: _startNewGame,
                                  ),
                                  const SizedBox(height: 10),
                                  _HudMenuButton(
                                    label: 'CONTINUE',
                                    onPressed:
                                        _hasSave ? () => _continueGame() : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _HudMenuButton(
                                    label: 'SETTINGS',
                                    onPressed: _openSettings,
                                  ),
                                  const SizedBox(height: 10),
                                  _HudMenuButton(
                                    label: 'TEACHER / PARENT MODE',
                                    onPressed: _openTeacherMode,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // HUD border on top (ignore pointer so buttons below receive taps)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: HudPanelBorder(
                              cornerLength: 20,
                              strokeWidth: 2,
                              glowRadius: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNewGame() async {
    if (!mounted) return;
    final provider = context.read<GameProvider>();

    // Check if player has set names
    if (provider.state.captainName.isEmpty || provider.state.shipName.isEmpty) {
      final result = await Navigator.of(context).push<bool>(
        pixelRoute(const PlayerIdentityScreen(isFirstTime: true)),
      );
      if (result != true || !mounted) return;
    }

    await provider.startNewGame();
    if (!mounted) return;
    await Navigator.of(context).push(pixelRoute(const GameScreen()));
    if (!mounted) return;
    await _checkSave();
  }

  Future<void> _continueGame() async {
    if (!mounted) return;
    final provider = context.read<GameProvider>();

    // Check if player has set names
    if (provider.state.captainName.isEmpty || provider.state.shipName.isEmpty) {
      final result = await Navigator.of(context).push<bool>(
        pixelRoute(const PlayerIdentityScreen(isFirstTime: true)),
      );
      if (result != true || !mounted) return;
    }

    // Start a new session for the continued game with same progress/ship
    await provider.dashboard.startSession();

    // Update session ID in game state using internal method
    final sessionId = provider.dashboard.getCurrentSessionId();
    provider.updateSessionId(sessionId);

    if (!mounted) return;
    await Navigator.of(context).push(pixelRoute(const GameScreen()));
    if (!mounted) return;
    await _checkSave();
  }

  Future<void> _openSettings() async {
    if (!mounted) return;
    await Navigator.of(context).push(pixelRoute(const SettingsScreen()));
    if (!mounted) return;
    await _checkSave();
  }

  void _openTeacherMode() {
    if (!mounted) return;
    Navigator.of(context).push(pixelRoute(const TeacherModeScreen()));
  }
}

class _HudMenuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _HudMenuButton({
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.phosphorGreenDim.withValues(alpha: 0.2)
                : AppTheme.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? AppTheme.phosphorGreen.withValues(alpha: 0.6)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppTheme.phosphorGreen.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: enabled ? Colors.white : Colors.grey,
                shadows: enabled ? AppTheme.terminalTextGlow : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
