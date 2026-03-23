import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/theme.dart';

class TravelLoadingOverlay extends StatefulWidget {
  const TravelLoadingOverlay({
    super.key,
    required this.fromSystem,
    required this.toSystem,
    required this.distanceUnits,
    required this.fuelRequired,
    required this.totalDuration,
  });

  final String fromSystem;
  final String toSystem;
  final int distanceUnits;
  final int fuelRequired;
  final Duration totalDuration;

  @override
  State<TravelLoadingOverlay> createState() => _TravelLoadingOverlayState();
}

class _TravelLoadingOverlayState extends State<TravelLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _starDriftController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _starDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _progressController = _buildProgressController(widget.totalDuration);
  }

  @override
  void didUpdateWidget(covariant TravelLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalDuration != widget.totalDuration) {
      _progressController.dispose();
      _progressController = _buildProgressController(widget.totalDuration);
    }
  }

  AnimationController _buildProgressController(Duration duration) {
    final controller = AnimationController(
      vsync: this,
      duration: duration == Duration.zero
          ? const Duration(milliseconds: 1)
          : duration,
    );
    controller.forward();
    return controller;
  }

  @override
  void dispose() {
    _starDriftController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds.remainder(60);
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_starDriftController, _progressController]),
      builder: (context, _) {
        final progress = _progressController.value.clamp(0.0, 1.0);
        final remaining = Duration(
          milliseconds:
              (widget.totalDuration.inMilliseconds * (1.0 - progress)).round(),
        );
        final percent = (progress * 100).round();

        return Container(
          color: Colors.black.withValues(alpha: 0.92),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _TravelStarfieldPainter(
                  phase: _starDriftController.value,
                  speed: 8,
                  density: 72,
                  brightness: 0.42,
                ),
              ),
              CustomPaint(
                painter: _TravelStarfieldPainter(
                  phase: _starDriftController.value,
                  speed: 18,
                  density: 44,
                  brightness: 0.65,
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.phosphorGreen.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.phosphorGreen.withValues(alpha: 0.18),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'IN TRANSIT',
                            textAlign: TextAlign.center,
                            style: AppTheme.terminalPrompt,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${widget.fromSystem} → ${widget.toSystem}',
                            textAlign: TextAlign.center,
                            style: AppTheme.terminalBody.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: progress,
                              backgroundColor:
                                  AppTheme.phosphorGreenDim.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.phosphorGreenBright,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$percent% • ETA ${_formatDuration(remaining)}',
                            textAlign: TextAlign.center,
                            style:
                                AppTheme.terminalLabel.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 220,
                              child: _StatTile(
                                label: 'FUEL',
                                value: '${widget.fuelRequired}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.phosphorGreenDim.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTheme.terminalLabel),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTheme.terminalBody.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TravelStarfieldPainter extends CustomPainter {
  _TravelStarfieldPainter({
    required this.phase,
    required this.speed,
    required this.density,
    required this.brightness,
  });

  final double phase;
  final double speed;
  final int density;
  final double brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42 + density + speed.round());
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < density; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 1.2;
      final alpha = (0.25 + rng.nextDouble() * 0.55) * brightness;

      final driftX = (phase * speed * 26 + i * 0.9) % (size.width + 40);
      final x = (baseX + driftX) % (size.width + 20) - 10;
      final y = baseY + sin((phase * 6) + i * 0.19) * 0.8;

      paint.color = AppTheme.phosphorGreen.withValues(alpha: alpha * 0.8);
      canvas.drawCircle(Offset(x, y), r, paint);

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), r * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TravelStarfieldPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.speed != speed ||
        oldDelegate.density != density ||
        oldDelegate.brightness != brightness;
  }
}
