import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/teacher_dashboard.dart';
import '../utils/theme.dart';
import '../utils/hud_panel_border.dart';
import '../utils/starfield_painter.dart';
import '../utils/grid_overlay_painter.dart';
import '../utils/reflection_grouping.dart';

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
    final sessionGroups = buildSessionReflectionGroups(
      reflections: dashboardData.reflections,
      sessions: dashboardData.sessions,
      deviceId: dashboardData.deviceId,
    );

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
            child: sessionGroups.isEmpty
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
                    itemCount: sessionGroups.length,
                    itemBuilder: (context, index) {
                      final group = sessionGroups[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _LogbookSessionEntry(
                          sessionNumber: index + 1,
                          group: group,
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
  final ValueChanged<ReflectionRecord> onEdit;

  const _LogbookSessionEntry({
    required this.sessionNumber,
    required this.group,
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
                      const SizedBox(height: 12),
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
