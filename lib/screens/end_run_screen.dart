import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/persistence_service.dart';
import '../utils/theme.dart';
import '../utils/hud_panel_border.dart';
import '../utils/starfield_painter.dart';
import '../utils/grid_overlay_painter.dart';
import '../utils/pixel_route.dart';
import 'menu_screen.dart';

class EndRunScreen extends StatefulWidget {
  const EndRunScreen({super.key});

  @override
  State<EndRunScreen> createState() => _EndRunScreenState();
}

class _EndRunScreenState extends State<EndRunScreen> {
  final _reflectionControllers = <TextEditingController>[];
  final _persistence = PersistenceService();
  bool _showReflection = true;

  final _reflectionQuestions = [
    'What was your most profitable trade route and why?',
    'What would you do differently in your next run?',
    'How did fuel costs affect your trading strategy?',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _reflectionQuestions.length; i++) {
      _reflectionControllers.add(TextEditingController());
    }
    _loadReflectionEnabled();
  }

  Future<void> _loadReflectionEnabled() async {
    final enabled = await _persistence.getReflectionEnabled();
    if (!mounted) return;
    setState(() {
      _showReflection = enabled;
    });
  }

  @override
  void dispose() {
    for (var controller in _reflectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    if (!mounted) return;
    final provider = context.read<GameProvider>();
    final sessionId = provider.state.currentSessionId;

    // Save reflections to dashboard if enabled
    if (_showReflection) {
      for (int i = 0; i < _reflectionQuestions.length; i++) {
        final answer = _reflectionControllers[i].text.trim();
        // Save even empty answers to preserve the question in the logbook
        await provider.dashboard.addReflection(
          sessionId: sessionId,
          question: _reflectionQuestions[i],
          answer: answer,
        );
      }
    }

    // End the current session
    await provider.dashboard.endSession();

    if (provider.sessionIsGameOver) {
      await _persistence.clearGameState();
      provider.clearSessionGameOver();
    } else {
      // Reset session stats and accumulate to lifetime stats
      provider.resetSessionStats();

      // Save game state with reset session stats
      await provider.saveGame();
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      pixelRoute(const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text('SESSION COMPLETE', style: AppTheme.appBarTitle),
        automaticallyImplyLeading: false,
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
          final state = provider.state;
          final netResult = state.credits - 1000;

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
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (state.captainName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: Text(
                                            'CAPTAIN ${state.captainName.toUpperCase()}',
                                            style: AppTheme.terminalLabel.copyWith(fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      _buildSummaryCard(
                                        'RUN SUMMARY',
                                        [
                                          const _SummaryRow(
                                              'Starting Credits', '1000'),
                                          _SummaryRow('Final Credits',
                                              '${state.credits}'),
                                          _SummaryRow(
                                              'Net Result', '$netResult',
                                              highlight: netResult >= 0),
                                          Container(
                                            height: 1,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.phosphorGreenDim
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          _SummaryRow('Total Fuel Used',
                                              '${state.totalFuelUsed}'),
                                          _SummaryRow('Credits Spent on Fuel',
                                              '${state.totalCreditsSpentOnFuel}'),
                                          _SummaryRow('Credits Spent on Goods',
                                              '${state.totalCreditsSpentOnGoods}'),
                                          _SummaryRow('Credits Spent on Upgrades',
                                              '${state.totalCreditsSpentOnUpgrades}'),
                                          _SummaryRow('Credits Earned',
                                              '${state.totalCreditsEarned}'),
                                        ],
                                      ),
                                      if (_showReflection) ...[
                                        const SizedBox(height: 20),
                                        _buildReflectionSection(),
                                      ],
                                      const SizedBox(height: 24),
                                      _buildHudButton(
                                        label: 'RETURN TO MENU',
                                        onPressed: _saveAndExit,
                                      ),
                                    ],
                                  ),
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

  Widget _buildHudButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.phosphorGreenDim.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.phosphorGreen.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.phosphorGreenBright,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.phosphorGreen.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.terminalBody.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReflectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.amber.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                'REFLECTION',
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.95),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Optional - skip or answer to help track your learning',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _reflectionQuestions.length; i++) ...[
            Text(
              '${i + 1}. ${_reflectionQuestions[i]}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reflectionControllers[i],
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Your answer (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppTheme.phosphorGreenDim.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.amber : AppTheme.phosphorGreenBright,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
