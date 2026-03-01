// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/teacher_dashboard.dart';
import '../utils/theme.dart';
import '../utils/hud_panel_border.dart';
import '../utils/starfield_painter.dart';
import '../utils/grid_overlay_painter.dart';
import '../utils/reflection_grouping.dart';
import '../widgets/end_run_summary.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final dashboardData = provider.dashboard.getData();
    final reflectionGroups = buildSessionReflectionGroups(
      reflections: dashboardData.reflections,
      sessions: dashboardData.sessions,
      deviceId: dashboardData.deviceId,
    );
    final reflectionsBySession = <String, List<ReflectionRecord>>{
      for (final group in reflectionGroups)
        group.sessionId: group.reflections,
    };
    final systemEntriesBySession = <String, List<SystemEntryRecord>>{};
    for (final entry in dashboardData.systemEntries) {
      systemEntriesBySession
          .putIfAbsent(entry.sessionId, () => [])
          .add(entry);
    }
    for (final entries in systemEntriesBySession.values) {
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    final sessionIds = <String>{
      ...reflectionsBySession.keys,
      ...systemEntriesBySession.keys,
    };
    final orderedSessions = [...dashboardData.sessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final sessionOrder = <String, int>{
      for (var index = 0; index < orderedSessions.length; index++)
        orderedSessions[index].id: index,
    };
    final orderedSessionIds = sessionIds.toList()
      ..sort((a, b) {
        final aOrder = sessionOrder[a];
        final bOrder = sessionOrder[b];

        if (aOrder != null && bOrder != null) {
          return aOrder.compareTo(bOrder);
        }
        if (aOrder != null) return -1;
        if (bOrder != null) return 1;

        final aReflections = reflectionsBySession[a] ?? const [];
        final bReflections = reflectionsBySession[b] ?? const [];
        final aEntries = systemEntriesBySession[a] ?? const [];
        final bEntries = systemEntriesBySession[b] ?? const [];

        final aTimes = <DateTime>[];
        final bTimes = <DateTime>[];
        if (aReflections.isNotEmpty) {
          aTimes.add(aReflections.first.timestamp);
        }
        if (aEntries.isNotEmpty) {
          aTimes.add(aEntries.first.timestamp);
        }
        if (bReflections.isNotEmpty) {
          bTimes.add(bReflections.first.timestamp);
        }
        if (bEntries.isNotEmpty) {
          bTimes.add(bEntries.first.timestamp);
        }

        if (aTimes.isEmpty && bTimes.isEmpty) {
          return a.compareTo(b);
        }
        if (aTimes.isEmpty) return 1;
        if (bTimes.isEmpty) return -1;

        final aTime = aTimes.reduce((a, b) => a.isBefore(b) ? a : b);
        final bTime = bTimes.reduce((a, b) => a.isBefore(b) ? a : b);
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text('CAPTAIN\'S LOGBOOK', style: AppTheme.appBarTitle),
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
            child: orderedSessionIds.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No logbook entries yet.\n\nComplete a session to add entries.',
                        style: AppTheme.terminalBody,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderedSessionIds.length,
                    itemBuilder: (context, index) {
                      final sessionId = orderedSessionIds[index];
                      final reflections =
                          reflectionsBySession[sessionId] ?? const [];
                      final group = SessionReflectionGroup(
                        sessionId: sessionId,
                        reflections: reflections,
                      );
                      // Find the matching session record for this group
                      final session = dashboardData.sessions.firstWhere(
                        (s) => s.id == sessionId,
                        orElse: () => SessionRecord(
                          id: '',
                          startTime: DateTime.now(),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _LogbookSessionEntry(
                          sessionNumber: index + 1,
                          group: group,
                          session: session.id.isNotEmpty ? session : null,
                          systemEntries:
                              systemEntriesBySession[sessionId] ?? [],
                          onEdit: (reflection) =>
                              _editReflection(context, reflection),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReflection(BuildContext context, ReflectionRecord reflection) async {
    final navigator = Navigator.of(context);
    final provider = context.read<GameProvider>();
    final result = await navigator.push<String>(
      MaterialPageRoute(
        builder: (context) => _EditReflectionScreen(reflection: reflection),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      await provider.dashboard.updateReflectionAnswer(
        reflectionId: reflection.id,
        newAnswer: result,
      );
      setState(() {});
    }
  }
}

class _LogbookSessionEntry extends StatelessWidget {
  final int sessionNumber;
  final SessionReflectionGroup group;
  final SessionRecord? session;
  final List<SystemEntryRecord> systemEntries;
  final ValueChanged<ReflectionRecord> onEdit;

  const _LogbookSessionEntry({
    required this.sessionNumber,
    required this.group,
    this.session,
    required this.systemEntries,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session $sessionNumber',
                        style: AppTheme.terminalBody.copyWith(
                          color: AppTheme.phosphorGreenBright,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Show End Run Summary if session data exists
                      if (session != null) ...[
                        EndRunSummary(
                          startingCredits: session?.startingCredits,
                          finalCredits: session?.finalCredits,
                          totalFuelUsed: session?.totalFuelUsed,
                          totalCreditsSpentOnFuel:
                              session?.totalCreditsSpentOnFuel,
                          totalCreditsSpentOnGoods:
                              session?.totalCreditsSpentOnGoods,
                          totalCreditsSpentOnUpgrades:
                              session?.totalCreditsSpentOnUpgrades,
                          totalCreditsEarned: session?.totalCreditsEarned,
                        ),
                        const SizedBox(height: 16),
                        if (systemEntries.isNotEmpty) ...[
                          // Divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              color: AppTheme.phosphorGreenDim
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'System Entry',
                            style: AppTheme.terminalBody.copyWith(
                              color: Colors.amber.withValues(alpha: 0.95),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final entry in systemEntries) ...[
                            Text(
                              'System History — ${entry.systemId}',
                              style: AppTheme.terminalBody.copyWith(
                                color: AppTheme.phosphorGreenBright,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.historyText,
                              style: AppTheme.terminalBody,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            color: AppTheme.phosphorGreenDim
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Reflections heading
                        Text(
                          'Reflections',
                          style: AppTheme.terminalBody.copyWith(
                            color: Colors.amber.withValues(alpha: 0.95),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Show reflections
                      for (var index = 0;
                          index < group.reflections.length;
                          index++) ...[
                        _ReflectionLineItem(
                          index: index,
                          reflection: group.reflections[index],
                          onEdit: () => onEdit(group.reflections[index]),
                        ),
                        if (index < group.reflections.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
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
    );
  }
}

class _ReflectionLineItem extends StatelessWidget {
  final int index;
  final ReflectionRecord reflection;
  final VoidCallback onEdit;

  const _ReflectionLineItem({
    required this.index,
    required this.reflection,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final question = reflection.question.trim().isEmpty
        ? '(No reflection question)'
        : reflection.question;
    final answer = reflection.answer.trim().isEmpty
        ? '(No answer)'
        : reflection.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '${index + 1}. $question',
                style: AppTheme.terminalBody.copyWith(
                  color: AppTheme.phosphorGreenBright,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'EDIT',
                    style: TextStyle(
                      color: AppTheme.phosphorGreen.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '• $answer',
          style: AppTheme.terminalBody,
        ),
      ],
    );
  }
}

class _EditReflectionScreen extends StatefulWidget {
  final ReflectionRecord reflection;

  const _EditReflectionScreen({required this.reflection});

  @override
  State<_EditReflectionScreen> createState() => _EditReflectionScreenState();
}

class _EditReflectionScreenState extends State<_EditReflectionScreen> {
  late TextEditingController _answerController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(text: widget.reflection.answer);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    if (!mounted) return;
    Navigator.of(context).pop(_answerController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        title: Text('EDIT ENTRY', style: AppTheme.appBarTitle),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'QUESTION',
                                    style: AppTheme.terminalLabel,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.reflection.question,
                                    style: AppTheme.terminalBody.copyWith(
                                      color: AppTheme.phosphorGreenBright,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'YOUR ANSWER',
                                    style: AppTheme.terminalLabel,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _answerController,
                                    style: AppTheme.terminalBody,
                                    maxLines: 8,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your answer',
                                      hintStyle: const TextStyle(
                                        color: AppTheme.phosphorGreenDim,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: AppTheme.phosphorGreen,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
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
                                              ? AppTheme.phosphorGreenDim.withValues(alpha: 0.2)
                                              : AppTheme.phosphorGreenDim.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _saving
                                                ? AppTheme.phosphorGreenDim
                                                : AppTheme.phosphorGreen.withValues(alpha: 0.6),
                                            width: 1,
                                          ),
                                          boxShadow: _saving
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color: AppTheme.phosphorGreen
                                                        .withValues(alpha: 0.15),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                        ),
                                        child: Center(
                                          child: _saving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    color: AppTheme.phosphorGreen,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'SAVE',
                                                  style: TextStyle(
                                                    color: AppTheme.phosphorGreenBright,
                                                    fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
