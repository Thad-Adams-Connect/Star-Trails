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
import '../utils/reflection_grouping.dart';
import '../widgets/end_run_summary.dart';

class TeacherModeScreen extends StatefulWidget {
  const TeacherModeScreen({super.key});

  @override
  State<TeacherModeScreen> createState() => _TeacherModeScreenState();
}

class _TeacherModeScreenState extends State<TeacherModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text('TEACHER/PARENT MODE', style: AppTheme.appBarTitle),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppTheme.phosphorGreenBright),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.phosphorGreenBright,
            labelColor: AppTheme.phosphorGreenBright,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Student Data'),
              Tab(text: 'Sessions'),
              Tab(text: 'Reflections'),
              Tab(text: 'Guidance'),
            ],
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
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStudentDataTab(context),
                            _buildSessionsTab(context),
                            _buildReflectionsTab(context),
                            _buildGuidanceTab(),
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
      ),
    );
  }

  Widget _buildStudentDataTab(BuildContext context) {
    final dashboard = context.read<GameProvider>().dashboard;
    final data = dashboard.getData();

    final playtimeHours = data.totalPlaytimeMs / 1000 / 3600;
    final playtimeMinutes =
        (data.totalPlaytimeMs / 1000 / 60).toStringAsFixed(0);

    // Count only completed sessions
    final completedSessionsCount =
        data.sessions.where((session) => session.endTime != null).length;

    // Calculate total trades across all sessions
    final totalTrades = data.sessions
        .fold<int>(0, (sum, session) => sum + session.tradesCompleted);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridOverlayPainter(spacing: 36),
          ),
        ),
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildDataSection(
              title: 'Device ID',
              content: [
                data.deviceId,
              ],
              icon: Icons.fingerprint,
            ),
            const SizedBox(height: 16),
            _buildDataSection(
              title: 'Total Playtime',
              content: [
                '$playtimeMinutes minutes (${playtimeHours.toStringAsFixed(1)} hours)',
              ],
              icon: Icons.timer,
            ),
            const SizedBox(height: 16),
            _buildDataSection(
              title: 'Completed Game Sessions',
              content: [
                'Total: $completedSessionsCount',
              ],
              icon: Icons.games,
            ),
            const SizedBox(height: 16),
            _buildDataSection(
              title: 'Total Trades Completed',
              content: [
                'Buys + Sells: $totalTrades',
              ],
              icon: Icons.swap_horiz,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionsTab(BuildContext context) {
    final dashboard = context.read<GameProvider>().dashboard;
    final data = dashboard.getData();

    // Only show completed sessions (those with endTime)
    final completedSessions =
        data.sessions.where((session) => session.endTime != null).toList();

    if (completedSessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No completed sessions yet.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridOverlayPainter(spacing: 36),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: completedSessions.length,
          itemBuilder: (context, index) {
            final session = completedSessions[index];
            final duration = session.durationMs ~/ 1000 ~/ 60;
            final durationSec = (session.durationMs ~/ 1000) % 60;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${index + 1}',
                      style: AppTheme.terminalBody.copyWith(
                        color: AppTheme.phosphorGreenBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show End Run Summary
                    EndRunSummary(
                      startingCredits: session.startingCredits,
                      finalCredits: session.finalCredits,
                      totalFuelUsed: session.totalFuelUsed,
                      totalCreditsSpentOnFuel: session.totalCreditsSpentOnFuel,
                      totalCreditsSpentOnGoods: session.totalCreditsSpentOnGoods,
                      totalCreditsSpentOnUpgrades:
                          session.totalCreditsSpentOnUpgrades,
                      totalCreditsEarned: session.totalCreditsEarned,
                    ),
                    const SizedBox(height: 16),
                    // Additional session info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Details',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Duration: $duration min $durationSec sec',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trades: ${session.tradesCompleted}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start: ${session.startTime.toString().split('.')[0]}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (session.endTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'End: ${session.endTime!.toString().split('.')[0]}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReflectionsTab(BuildContext context) {
    final dashboard = context.read<GameProvider>().dashboard;
    final data = dashboard.getData();
    final sessionGroups = buildSessionReflectionGroups(
      reflections: data.reflections,
      sessions: data.sessions,
      deviceId: data.deviceId,
    );

    if (sessionGroups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No reflections recorded yet.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridOverlayPainter(spacing: 36),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sessionGroups.length,
          itemBuilder: (context, index) {
            final group = sessionGroups[index];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${index + 1}',
                      style: AppTheme.terminalBody.copyWith(
                        color: AppTheme.phosphorGreenBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reflections
                    Text(
                      'Reflections',
                      style: TextStyle(
                        color: Colors.amber.withValues(alpha: 0.95),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var reflectionIndex = 0;
                        reflectionIndex < group.reflections.length;
                        reflectionIndex++) ...[
                      Text(
                        '${reflectionIndex + 1}. ${group.reflections[reflectionIndex].question.trim().isEmpty ? "(No reflection question)" : group.reflections[reflectionIndex].question}',
                        style: const TextStyle(
                          color: AppTheme.phosphorGreenBright,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• ${group.reflections[reflectionIndex].answer.trim().isEmpty ? "(No answer)" : group.reflections[reflectionIndex].answer}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      if (reflectionIndex < group.reflections.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGuidanceTab() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridOverlayPainter(spacing: 36),
          ),
        ),
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              icon: Icons.school,
              title: 'Learning Goals',
              content: [
                'Mathematical reasoning: profit/loss calculations',
                'Resource management: balancing fuel and cargo',
                'Strategic planning: route optimization',
                'Economic concepts: supply/demand, arbitrage',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.visibility,
              title: 'What to Observe',
              content: [
                'Decision-making: How does the student choose routes?',
                'Mathematical thinking: Are they calculating profits?',
                'Adaptive learning: Do strategies adjust over time?',
                'Resource awareness: Do they monitor fuel/cargo?',
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              icon: Icons.tips_and_updates,
              title: 'Discussion Prompts',
              content: [
                'Why do prices differ between planets?',
                'How did you decide which route to take?',
                'What happened when you sold repeatedly?',
                'How much profit per trip?',
                'What would you do differently?',
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataSection({
    required String title,
    required List<String> content,
    required IconData icon,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.phosphorGreenBright, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.phosphorGreenBright,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var item in content)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> content,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppTheme.phosphorGreenBright),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.terminalBody.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var item in content)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppTheme.phosphorGreenBright,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
