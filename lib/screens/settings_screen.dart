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
import 'player_identity_screen.dart';
import '../utils/pixel_route.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text('SETTINGS', style: AppTheme.appBarTitle),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppTheme.phosphorGreenBright),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: AppTheme.phosphorGreenDim,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.phosphorGreen.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: StarfieldPainter(),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: GridOverlayPainter(spacing: 36),
                                  ),
                                ),
                                ListView(
                                  padding: const EdgeInsets.all(20),
                                  children: [
                                    _buildActionTile(
                                      context,
                                      icon: Icons.person_outline,
                                      title: 'Edit Identity',
                                      subtitle: 'Change captain and ship name',
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          pixelRoute(
                                            const PlayerIdentityScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildSettingTile(
                                      context,
                                      icon: Icons.lightbulb_outline,
                                      title: 'Educational Prompts',
                                      subtitle:
                                          'Show learning tips during gameplay',
                                      value: provider.eduPromptsEnabled,
                                      onChanged: (value) =>
                                          provider.setEduPromptsEnabled(value),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildSettingTile(
                                      context,
                                      icon: Icons.school,
                                      title: 'Reflection Questions',
                                      subtitle: 'Show reflection at end of run',
                                      value: provider.reflectionEnabled,
                                      onChanged: (value) =>
                                          provider.setReflectionEnabled(value),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildNarrativeTextSpeedTile(
                                      context,
                                      icon: Icons.speed,
                                      title: 'Narrative Text Speed',
                                      subtitle:
                                          'Adjust typing speed for intro and system history text',
                                      value:
                                          provider.narrativeTextSpeedMultiplier,
                                      onChanged: (value) => provider
                                          .setNarrativeTextSpeedMultiplier(
                                              value),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: HudPanelBorder(
                                  cornerLength: 16,
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
          );
        },
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.phosphorGreenDim.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.phosphorGreen.withValues(alpha: 0.08),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.phosphorGreenBright),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.phosphorGreen.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.phosphorGreen.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.phosphorGreenBright),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _RectToggleButton(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeTextSpeedTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.phosphorGreen.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.phosphorGreenBright),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.phosphorGreenDim.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.phosphorGreen.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '${value.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    color: AppTheme.phosphorGreenBright,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.phosphorGreenBright,
              inactiveTrackColor:
                  AppTheme.phosphorGreen.withValues(alpha: 0.35),
              thumbColor: AppTheme.phosphorGreenBright,
              overlayColor: AppTheme.phosphorGreen.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RectToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RectToggleButton({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.phosphorGreenDim.withValues(alpha: 0.3)
                : AppTheme.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
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
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(enabled ? Icons.check : Icons.close,
                  size: 18,
                  color: enabled ? AppTheme.phosphorGreenBright : Colors.grey),
              const SizedBox(width: 8),
              Text(
                enabled ? 'ON' : 'OFF',
                style: TextStyle(
                  color: enabled ? AppTheme.phosphorGreenBright : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
