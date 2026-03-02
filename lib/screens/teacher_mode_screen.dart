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

class _TeacherModeScreenState extends State<TeacherModeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            DefaultTabController(
                              length: 4,
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  _TeacherModeTabBar(),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _buildStudentDataTab(context),
                                        _buildSessionsTab(context),
                                        _buildReflectionsTab(context),
                                        _buildGuidanceTab(),
                                      ],
                                    ),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _NotebookSectionCard(
          title: 'Device ID',
          icon: Icons.fingerprint,
          child: Text(
            data.deviceId,
            style: AppTheme.terminalBody.copyWith(
              color: AppTheme.phosphorGreenBright,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NotebookSectionCard(
          title: 'Total Playtime',
          icon: Icons.timer,
          child: Text(
            '$playtimeMinutes min (${playtimeHours.toStringAsFixed(1)} hrs)',
            style: AppTheme.terminalBody.copyWith(
              color: AppTheme.phosphorGreenBright,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NotebookSectionCard(
          title: 'Completed Sessions',
          icon: Icons.games,
          child: Text(
            '$completedSessionsCount',
            style: AppTheme.terminalBody.copyWith(
              color: AppTheme.phosphorGreenBright,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NotebookSectionCard(
          title: 'Total Trades',
          icon: Icons.swap_horiz,
          child: Text(
            '$totalTrades',
            style: AppTheme.terminalBody.copyWith(
              color: AppTheme.phosphorGreenBright,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsTab(BuildContext context) {
    final dashboard = context.read<GameProvider>().dashboard;
    final data = dashboard.getData();
    final systemEntriesBySession = <String, List<dynamic>>{};
    for (final entry in data.systemEntries) {
      systemEntriesBySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }
    for (final entries in systemEntriesBySession.values) {
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: completedSessions.length,
      itemBuilder: (context, index) {
        final session = completedSessions[index];
        final systemEntries =
            systemEntriesBySession[session.id] ?? const <dynamic>[];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NotebookSectionCard(
            title: 'Session ${index + 1} Recap',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndRunSummary(
                  startingCredits: session.startingCredits,
                  finalCredits: session.finalCredits,
                  totalFuelUsed: session.totalFuelUsed,
                  totalCreditsSpentOnFuel: session.totalCreditsSpentOnFuel,
                  totalCreditsSpentOnGoods:
                      session.totalCreditsSpentOnGoods,
                  totalCreditsSpentOnUpgrades:
                      session.totalCreditsSpentOnUpgrades,
                  totalCreditsEarned: session.totalCreditsEarned,
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: AppTheme.phosphorGreenDim.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Performance Metrics',
                  style: AppTheme.terminalBody.copyWith(
                    color: Colors.amber.withValues(alpha: 0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  label: 'Session Duration',
                  value: _formatDuration(session.durationMs),
                ),
                _MetricRow(
                  label: 'Missions Completed',
                  value: '${session.missionsCompleted}',
                ),
                _MetricRow(
                  label: 'Trades Completed',
                  value: '${session.tradesCompleted}',
                ),
                if (systemEntries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: AppTheme.phosphorGreenDim.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'System Entry Highlights',
                    style: AppTheme.terminalBody.copyWith(
                      color: Colors.amber.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in systemEntries) ...[
                    Text(
                      '• ${entry.systemId}',
                      style: AppTheme.terminalBody.copyWith(
                        color: AppTheme.phosphorGreenBright,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.historyText, style: AppTheme.terminalBody),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: AppTheme.phosphorGreenDim.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Session Times',
                  style: AppTheme.terminalBody.copyWith(
                    color: Colors.amber.withValues(alpha: 0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  label: 'Start',
                  value: session.startTime.toString().split('.')[0],
                ),
                if (session.endTime != null)
                  _MetricRow(
                    label: 'End',
                    value: session.endTime!.toString().split('.')[0],
                  ),
              ],
            ),
          ),
        );
      },
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: sessionGroups.length,
      itemBuilder: (context, index) {
        final group = sessionGroups[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NotebookSectionCard(
            title: 'Session ${index + 1} — Student Reflections',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var reflectionIndex = 0;
                    reflectionIndex < group.reflections.length;
                    reflectionIndex++) ...[
                  Text(
                    '${reflectionIndex + 1}. ${group.reflections[reflectionIndex].question.trim().isEmpty ? "(No reflection question)" : group.reflections[reflectionIndex].question}',
                    style: const TextStyle(
                      color: AppTheme.phosphorGreenBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.reflections[reflectionIndex].answer.trim().isEmpty ? '(No answer)' : group.reflections[reflectionIndex].answer,
                    style: AppTheme.terminalBody,
                  ),
                  if (reflectionIndex < group.reflections.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidanceTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _NotebookSectionCard(
          title: 'Learning Goals',
          icon: Icons.school,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BulletPoint(text: 'Mathematical reasoning: profit/loss calculations'),
              _BulletPoint(text: 'Resource management: balancing fuel and cargo'),
              _BulletPoint(text: 'Strategic planning: route optimization'),
              _BulletPoint(text: 'Economic concepts: supply/demand, arbitrage'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NotebookSectionCard(
          title: 'What to Observe',
          icon: Icons.visibility,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BulletPoint(text: 'Decision-making: How does the student choose routes?'),
              _BulletPoint(text: 'Mathematical thinking: Are they calculating profits?'),
              _BulletPoint(text: 'Adaptive learning: Do strategies adjust over time?'),
              _BulletPoint(text: 'Resource awareness: Do they monitor fuel/cargo?'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NotebookSectionCard(
          title: 'Discussion Prompts',
          icon: Icons.tips_and_updates,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BulletPoint(text: 'Why do prices differ between planets?'),
              _BulletPoint(text: 'How did you decide which route to take?'),
              _BulletPoint(text: 'What happened when you sold repeatedly?'),
              _BulletPoint(text: 'How much profit per trip?'),
              _BulletPoint(text: 'What would you do differently?'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) return 'N/A';
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

class _TeacherModeTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 9.0),
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      labelColor: AppTheme.phosphorGreenBright,
      unselectedLabelColor: AppTheme.phosphorGreen.withValues(alpha: 0.8),
      labelStyle: AppTheme.terminalBody.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: AppTheme.terminalBody.copyWith(
        fontSize: 14,
        letterSpacing: 0.5,
      ),
      tabs: const [
        Tab(text: 'STUDENT DATA'),
        Tab(text: 'SESSIONS'),
        Tab(text: 'REFLECTIONS'),
        Tab(text: 'GUIDANCE'),
      ],
    );
  }
}

class _NotebookSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _NotebookSectionCard({
    required this.title,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.phosphorGreen.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.amber.withValues(alpha: 0.95),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.terminalBody.copyWith(
                      color: Colors.amber.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.phosphorGreenBright,
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

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppTheme.phosphorGreenBright,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.terminalBody.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
