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
                                      subtitle:
                                          'Change captain and ship name',
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          pixelRoute(
                                            const PlayerIdentityScreen(),
                                          ),
                                        );
                                      },
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
}
