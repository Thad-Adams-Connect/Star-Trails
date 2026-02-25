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

class PlayerIdentityScreen extends StatefulWidget {
  final bool isFirstTime;

  const PlayerIdentityScreen({super.key, this.isFirstTime = false});

  @override
  State<PlayerIdentityScreen> createState() => _PlayerIdentityScreenState();
}

class _PlayerIdentityScreenState extends State<PlayerIdentityScreen> {
  final TextEditingController _captainController = TextEditingController();
  final TextEditingController _shipController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    _captainController.text = provider.state.captainName;
    _shipController.text = provider.state.shipName;
  }

  @override
  void dispose() {
    _captainController.dispose();
    _shipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final captainName = _captainController.text.trim();
    final shipName = _shipController.text.trim();

    if (captainName.isEmpty || shipName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both captain and ship names.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    if (!mounted) return;
    final provider = context.read<GameProvider>();
    await provider.updatePlayerNames(
      captainName: captainName,
      shipName: shipName,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text(
          widget.isFirstTime ? 'WELCOME, CAPTAIN' : 'IDENTITY',
          style: AppTheme.appBarTitle,
        ),
        automaticallyImplyLeading: !widget.isFirstTime,
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomPaint(
                              painter: GridOverlayPainter(spacing: 36),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (widget.isFirstTime) ...[
                                      Text(
                                        'Enter your identity for the ship logs and records.',
                                        style: AppTheme.terminalBody,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    Text(
                                      'CAPTAIN NAME',
                                      style: AppTheme.terminalLabel,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _captainController,
                                      style: AppTheme.terminalPrompt,
                                      decoration: InputDecoration(
                                        hintText: 'Enter captain name',
                                        hintStyle: const TextStyle(
                                          color: AppTheme.phosphorGreenDim,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.black.withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: AppTheme.phosphorGreen
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                            color: AppTheme.phosphorGreen,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                            color: AppTheme.phosphorGreenBright,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      enabled: !_saving,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'SHIP NAME',
                                      style: AppTheme.terminalLabel,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _shipController,
                                      style: AppTheme.terminalPrompt,
                                      decoration: InputDecoration(
                                        hintText: 'Enter ship name',
                                        hintStyle: const TextStyle(
                                          color: AppTheme.phosphorGreenDim,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.black.withValues(alpha: 0.5),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: AppTheme.phosphorGreen
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                            color: AppTheme.phosphorGreen,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: const BorderSide(
                                            color: AppTheme.phosphorGreenBright,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      enabled: !_saving,
                                    ),
                                    const SizedBox(height: 32),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _saving ? null : _save,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _saving
                                                ? AppTheme.phosphorGreenDim
                                                    .withValues(alpha: 0.2)
                                                : AppTheme.phosphorGreenDim
                                                    .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _saving
                                                  ? AppTheme.phosphorGreenDim
                                                  : AppTheme.phosphorGreen
                                                      .withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                            boxShadow: _saving
                                                ? []
                                                : [
                                                    BoxShadow(
                                                      color: AppTheme
                                                          .phosphorGreen
                                                          .withValues(
                                                              alpha: 0.15),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                          ),
                                          child: Center(
                                            child: _saving
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: AppTheme
                                                          .phosphorGreen,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'SAVE',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .phosphorGreenBright,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'monospace',
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: HudPanelBorder(
                                  cornerLength: 20,
                                  strokeWidth: 2,
                                  glowRadius: 8,
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
            ),
          ),
        ],
      ),
    );
  }
}
