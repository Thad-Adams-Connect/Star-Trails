// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/demo_disclaimer.dart';
import '../data/intro_story.dart';
import '../data/system_histories.dart';
import '../models/teacher_dashboard.dart';
import '../providers/game_provider.dart';
import '../utils/app_version.dart';
import '../utils/grid_overlay_painter.dart';
import '../utils/hud_panel_border.dart';
import '../utils/reflection_grouping.dart';
import '../utils/starfield_painter.dart';
import '../utils/theme.dart';
import '../utils/pixel_route.dart';
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
      for (final group in reflectionGroups) group.sessionId: group.reflections,
    };

    final systemEntriesBySession = <String, List<SystemEntryRecord>>{};
    for (final entry in dashboardData.systemEntries) {
      systemEntriesBySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }
    for (final entries in systemEntriesBySession.values) {
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    // Only show completed sessions (those with endTime and run summary data)
    final completedSessions = dashboardData.sessions
        .where((session) =>
            session.endTime != null &&
            (session.startingCredits != null ||
                session.finalCredits != null ||
                session.totalFuelUsed != null))
        .toList();

    final orderedSessions = [...completedSessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final sessionOrder = <String, int>{
      for (var index = 0; index < orderedSessions.length; index++)
        orderedSessions[index].id: index,
    };

    final sessionIds = <String>{
      ...reflectionsBySession.keys,
      ...systemEntriesBySession.keys,
      ...orderedSessions.map((s) => s.id),
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

        final aTime = aTimes.reduce((x, y) => x.isBefore(y) ? x : y);
        final bTime = bTimes.reduce((x, y) => x.isBefore(y) ? x : y);
        return aTime.compareTo(bTime);
      });

    final sessionNumberById = <String, int>{
      for (var index = 0; index < orderedSessionIds.length; index++)
        orderedSessionIds[index]: index + 1,
    };

    final allWisdom = _buildWisdomEntries(
      wisdomEntries: dashboardData.wisdomEntries,
    );
    final showDemoDisclaimer = AppVersion.editionCode.startsWith('EDU');

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
                              length: 5,
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  _NotebookTabBar(),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _SessionRecapsSection(
                                          sessions: orderedSessions,
                                          systemEntriesBySession:
                                              systemEntriesBySession,
                                          showDemoDisclaimer:
                                              showDemoDisclaimer,
                                        ),
                                        _CaptainsLogSection(
                                          orderedSessionIds: orderedSessionIds,
                                          sessionNumberById: sessionNumberById,
                                          reflectionsBySession:
                                              reflectionsBySession,
                                          showDemoDisclaimer:
                                              showDemoDisclaimer,
                                          onEdit: (reflection) =>
                                              _editReflection(
                                                  context, reflection),
                                        ),
                                        _IntroAndHistoriesSection(
                                          systemEntriesBySession:
                                              systemEntriesBySession,
                                          sessionNumberById: sessionNumberById,
                                          captainName:
                                              provider.state.captainName,
                                          shipName: provider.state.shipName,
                                          isIntroActive:
                                              provider.state.isIntroActive,
                                          firstChoiceActive:
                                              provider.state.firstChoiceActive,
                                          showDemoDisclaimer:
                                              showDemoDisclaimer,
                                        ),
                                        _WordsOfWisdomSection(
                                          wisdomEntries: allWisdom,
                                          showDemoDisclaimer:
                                              showDemoDisclaimer,
                                        ),
                                        _CalculatorsSection(
                                          showDemoDisclaimer:
                                              showDemoDisclaimer,
                                        ),
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

  List<String> _buildWisdomEntries({
    required List<WisdomDisplayRecord> wisdomEntries,
  }) {
    // Return wisdom text in reverse chronological order (newest first)
    final sortedWisdom = [...wisdomEntries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return [for (final entry in sortedWisdom) entry.text];
  }

  Future<void> _editReflection(
      BuildContext context, ReflectionRecord reflection) async {
    final navigator = Navigator.of(context);
    final provider = context.read<GameProvider>();
    final result = await navigator.push<String>(
      pixelRoute(_EditReflectionScreen(reflection: reflection)),
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

class _NotebookTabBar extends StatelessWidget {
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
        Tab(text: 'SESSION RECAPS'),
        Tab(text: 'CAPTAIN\'S LOG'),
        Tab(text: 'INTRO & HISTORIES'),
        Tab(text: 'WORDS OF WISDOM'),
        Tab(text: 'CALCULATORS'),
      ],
    );
  }
}

class _SessionRecapsSection extends StatelessWidget {
  final List<SessionRecord> sessions;
  final Map<String, List<SystemEntryRecord>> systemEntriesBySession;
  final bool showDemoDisclaimer;

  const _SessionRecapsSection({
    required this.sessions,
    required this.systemEntriesBySession,
    required this.showDemoDisclaimer,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      if (showDemoDisclaimer) {
        return const _EmptySectionWithFooter(
          message:
              'No session recaps yet.\n\nComplete a run to populate this section.',
        );
      }
      return const _EmptySectionMessage(
        message:
            'No session recaps yet.\n\nComplete a run to populate this section.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: sessions.length + (showDemoDisclaimer ? 1 : 0),
      itemBuilder: (context, index) {
        if (showDemoDisclaimer && index == sessions.length) {
          return const _DemoDisclaimerFooter();
        }

        final session = sessions[index];

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
                  totalCreditsSpentOnGoods: session.totalCreditsSpentOnGoods,
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
              ],
            ),
          ),
        );
      },
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

class _CaptainsLogSection extends StatelessWidget {
  final List<String> orderedSessionIds;
  final Map<String, int> sessionNumberById;
  final Map<String, List<ReflectionRecord>> reflectionsBySession;
  final bool showDemoDisclaimer;
  final ValueChanged<ReflectionRecord> onEdit;

  const _CaptainsLogSection({
    required this.orderedSessionIds,
    required this.sessionNumberById,
    required this.reflectionsBySession,
    required this.showDemoDisclaimer,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sessionsWithReflections = orderedSessionIds
        .where((id) => (reflectionsBySession[id] ?? const []).isNotEmpty)
        .toList();

    if (sessionsWithReflections.isEmpty) {
      if (showDemoDisclaimer) {
        return const _EmptySectionWithFooter(
          message:
              'No captain reflections yet.\n\nComplete an end-run reflection to add entries.',
        );
      }
      return const _EmptySectionMessage(
        message:
            'No captain reflections yet.\n\nComplete an end-run reflection to add entries.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: sessionsWithReflections.length + (showDemoDisclaimer ? 1 : 0),
      itemBuilder: (context, index) {
        if (showDemoDisclaimer && index == sessionsWithReflections.length) {
          return const _DemoDisclaimerFooter();
        }

        final sessionId = sessionsWithReflections[index];
        final reflections = reflectionsBySession[sessionId] ?? const [];
        final sessionNumber = sessionNumberById[sessionId] ?? (index + 1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NotebookSectionCard(
            title: 'Session $sessionNumber — Personal Notes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < reflections.length; i++) ...[
                  _ReflectionLineItem(
                    index: i,
                    reflection: reflections[i],
                    onEdit: () => onEdit(reflections[i]),
                  ),
                  if (i < reflections.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IntroAndHistoriesSection extends StatelessWidget {
  final Map<String, List<SystemEntryRecord>> systemEntriesBySession;
  final Map<String, int> sessionNumberById;
  final String captainName;
  final String shipName;
  final bool isIntroActive;
  final bool firstChoiceActive;
  final bool showDemoDisclaimer;

  const _IntroAndHistoriesSection({
    required this.systemEntriesBySession,
    required this.sessionNumberById,
    required this.captainName,
    required this.shipName,
    required this.isIntroActive,
    required this.firstChoiceActive,
    required this.showDemoDisclaimer,
  });

  String _getPersonalizedIntro() {
    var personalizedIntro = introStoryText;

    final resolvedShipName = shipName.trim().isNotEmpty
        ? shipName.trim()
        : 'Opportunity for ship name';
    final resolvedCaptainName = captainName.trim().isNotEmpty
        ? captainName.trim()
        : 'Opportunity for name';

    personalizedIntro = personalizedIntro.replaceFirst(
      '[SHIP_NAME]',
      resolvedShipName,
    );

    personalizedIntro = personalizedIntro.replaceFirst(
      '[CAPTAIN_NAME]',
      resolvedCaptainName,
    );

    return personalizedIntro;
  }

  @override
  Widget build(BuildContext context) {
    // If intro is still playing or first choice is active, show placeholder
    if (isIntroActive || firstChoiceActive) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _NotebookSectionCard(
            title: 'Game Introduction',
            child: const _StructuredParagraphText(
              text:
                  'The introduction sequence is currently playing...\n\nOnce you complete the intro and begin your first trading run, your personalized introduction will appear here.',
            ),
          ),
          const SizedBox(height: 20),
          const _EmptySectionMessage(
            message: 'Travel to new systems to discover their histories.',
          ),
          if (showDemoDisclaimer) ...[
            const SizedBox(height: 20),
            const _DemoDisclaimerFooter(),
          ],
        ],
      );
    }

    final allSystemHistories = <MapEntry<String, String>>[
      ...innerRingSystemHistories.entries,
      ...outerSystemHistories.entries,
    ];

    final discoveredSystems = <String, List<String>>{};
    final orderedSessionIds = sessionNumberById.keys.toList()
      ..sort((a, b) => (sessionNumberById[a] ?? 0).compareTo(
            sessionNumberById[b] ?? 0,
          ));

    for (final sessionId in orderedSessionIds) {
      final sessionNumber = sessionNumberById[sessionId] ?? 0;
      final entries = systemEntriesBySession[sessionId] ?? const [];
      for (final entry in entries) {
        discoveredSystems.putIfAbsent(entry.systemId, () => []);
        discoveredSystems[entry.systemId]!.add('Session $sessionNumber');
      }
    }

    // Only show discovered system histories
    final discoveredHistories = allSystemHistories
        .where((h) => discoveredSystems.containsKey(h.key))
        .toList();

    if (discoveredHistories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _NotebookSectionCard(
            title: 'Game Introduction',
            child: _StructuredParagraphText(text: _getPersonalizedIntro()),
          ),
          const SizedBox(height: 20),
          const _EmptySectionMessage(
            message: 'Travel to new systems to discover their histories.',
          ),
          if (showDemoDisclaimer) ...[
            const SizedBox(height: 20),
            const _DemoDisclaimerFooter(),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _NotebookSectionCard(
          title: 'Game Introduction',
          child: _StructuredParagraphText(text: _getPersonalizedIntro()),
        ),
        const SizedBox(height: 20),
        for (final history in discoveredHistories) ...[
          const SizedBox(height: 8),
          _NotebookSectionCard(
            title: history.key,
            subtitle:
                'Discovered: ${discoveredSystems[history.key]!.join(', ')}',
            child: _StructuredParagraphText(text: history.value),
          ),
          const SizedBox(height: 20),
        ],
        if (showDemoDisclaimer) const _DemoDisclaimerFooter(),
      ],
    );
  }
}

class _WordsOfWisdomSection extends StatelessWidget {
  final List<String> wisdomEntries;
  final bool showDemoDisclaimer;

  const _WordsOfWisdomSection({
    required this.wisdomEntries,
    required this.showDemoDisclaimer,
  });

  @override
  Widget build(BuildContext context) {
    if (wisdomEntries.isEmpty) {
      if (showDemoDisclaimer) {
        return const _EmptySectionWithFooter(
          message: 'No words of wisdom yet.',
        );
      }
      return const _EmptySectionMessage(
        message: 'No words of wisdom yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: wisdomEntries.length + (showDemoDisclaimer ? 1 : 0),
      itemBuilder: (context, index) {
        if (showDemoDisclaimer && index == wisdomEntries.length) {
          return const _DemoDisclaimerFooter();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NotebookSectionCard(
            title: 'Wisdom ${index + 1}',
            child: Text(
              wisdomEntries[index],
              style: AppTheme.terminalBody,
            ),
          ),
        );
      },
    );
  }
}

class _CalculatorsSection extends StatefulWidget {
  final bool showDemoDisclaimer;

  const _CalculatorsSection({required this.showDemoDisclaimer});

  @override
  State<_CalculatorsSection> createState() => _CalculatorsSectionState();
}

class _CalculatorsSectionState extends State<_CalculatorsSection> {
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  int? _historyIndex;
  String _historyDraftBuyPrice = '';
  String _historyDraftSellPrice = '';
  String _historyDraftQuantity = '';

  void _handleFieldChanged(String _) {
    if (_historyIndex != null) {
      _historyIndex = null;
      _historyDraftBuyPrice = _buyPriceController.text;
      _historyDraftSellPrice = _sellPriceController.text;
      _historyDraftQuantity = _quantityController.text;
    }

    setState(() {});
  }

  KeyEventResult _onCalculationInputKeyEvent(
    KeyEvent event,
    List<TradingCalculationRecord> calculationHistory,
  ) {
    if (event is! KeyDownEvent || calculationHistory.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _navigateCalculationHistory(-1, calculationHistory);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _navigateCalculationHistory(1, calculationHistory);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _navigateCalculationHistory(
    int direction,
    List<TradingCalculationRecord> calculationHistory,
  ) {
    if (calculationHistory.isEmpty) {
      return;
    }

    if (_historyIndex == null) {
      if (direction > 0) {
        return;
      }

      _historyDraftBuyPrice = _buyPriceController.text;
      _historyDraftSellPrice = _sellPriceController.text;
      _historyDraftQuantity = _quantityController.text;
      _historyIndex = 0;
      _setCalculationInputs(calculationHistory[_historyIndex!]);
      setState(() {});
      return;
    }

    final nextIndex = _historyIndex! - direction;
    if (nextIndex < 0) {
      _historyIndex = null;
      _restoreCalculationDraft();
      setState(() {});
      return;
    }

    if (nextIndex >= calculationHistory.length) {
      _historyIndex = null;
      _restoreCalculationDraft();
      setState(() {});
      return;
    }

    _historyIndex = nextIndex;
    _setCalculationInputs(calculationHistory[_historyIndex!]);
    setState(() {});
  }

  void _setCalculationInputs(TradingCalculationRecord calculation) {
    _setControllerValue(_buyPriceController, '${calculation.buyPrice}');
    _setControllerValue(_sellPriceController, '${calculation.sellPrice}');
    _setControllerValue(_quantityController, '${calculation.quantity}');
  }

  void _restoreCalculationDraft() {
    _setControllerValue(_buyPriceController, _historyDraftBuyPrice);
    _setControllerValue(_sellPriceController, _historyDraftSellPrice);
    _setControllerValue(_quantityController, _historyDraftQuantity);
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _saveCalculation() async {
    final buyPrice = int.tryParse(_buyPriceController.text.trim());
    final sellPrice = int.tryParse(_sellPriceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());

    if (buyPrice == null || sellPrice == null || quantity == null) {
      return;
    }

    final provider = context.read<GameProvider>();
    await provider.dashboard.addTradingCalculation(
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      quantity: quantity,
    );

    if (!mounted) {
      return;
    }

    _historyIndex = null;
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _clearInputs() {
    _buyPriceController.clear();
    _sellPriceController.clear();
    _quantityController.clear();
    _historyIndex = null;
    _historyDraftBuyPrice = '';
    _historyDraftSellPrice = '';
    _historyDraftQuantity = '';
    setState(() {});
  }

  String _formatCalculationTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} $hour:$minute $meridiem';
  }

  @override
  void dispose() {
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.read<GameProvider>().dashboard;
    final calculationHistory =
        dashboard.getTradingCalculations().reversed.toList();
    final buyPrice = int.tryParse(_buyPriceController.text.trim());
    final sellPrice = int.tryParse(_sellPriceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    final hasValidInputs =
        buyPrice != null && sellPrice != null && quantity != null;
    final tradeProfit =
        hasValidInputs ? (sellPrice - buyPrice) * quantity : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _NotebookSectionCard(
          title: 'Trading Calculator',
          subtitle: 'Formula Reference',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Trade Profit = (Sell Price - Buy Price) × Quantity',
                  style: AppTheme.terminalBody.copyWith(
                    color: AppTheme.phosphorGreenBright,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Use this to estimate credits gained per trade run.',
                style: AppTheme.terminalBody.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CalcField(
                      label: 'Buy Price',
                      controller: _buyPriceController,
                      onChanged: _handleFieldChanged,
                      onKeyEvent: (event) => _onCalculationInputKeyEvent(
                          event, calculationHistory),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CalcField(
                      label: 'Sell Price',
                      controller: _sellPriceController,
                      onChanged: _handleFieldChanged,
                      onKeyEvent: (event) => _onCalculationInputKeyEvent(
                          event, calculationHistory),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CalcField(
                      label: 'Quantity',
                      controller: _quantityController,
                      onChanged: _handleFieldChanged,
                      onKeyEvent: (event) => _onCalculationInputKeyEvent(
                          event, calculationHistory),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Projected Profit',
                value: tradeProfit == null ? 'N/A' : '$tradeProfit cr',
                highlight: tradeProfit != null,
                positive: (tradeProfit ?? 0) >= 0,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: hasValidInputs ? _saveCalculation : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: AppTheme.phosphorGreen.withValues(alpha: 0.65),
                        ),
                        foregroundColor: AppTheme.phosphorGreenBright,
                        textStyle: AppTheme.terminalBody.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('ADD TO HISTORY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearInputs,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        foregroundColor: Colors.white70,
                        textStyle: AppTheme.terminalBody.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('CLEAR FIELDS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (calculationHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var index = 0; index < calculationHistory.length; index++) ...[
            _NotebookSectionCard(
              title: 'Calculation ${calculationHistory.length - index}',
              subtitle:
                  'Trading Calculator • ${_formatCalculationTimestamp(calculationHistory[index].timestamp)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy: ${calculationHistory[index].buyPrice} cr  |  Sell: ${calculationHistory[index].sellPrice} cr  |  Qty: ${calculationHistory[index].quantity}',
                    style: AppTheme.terminalBody.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '(${calculationHistory[index].sellPrice} - ${calculationHistory[index].buyPrice}) × ${calculationHistory[index].quantity}',
                    style: AppTheme.terminalBody.copyWith(
                      color: AppTheme.phosphorGreenBright,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MetricRow(
                    label: 'Projected Profit',
                    value: '${calculationHistory[index].projectedProfit} cr',
                    highlight: true,
                    positive: calculationHistory[index].projectedProfit >= 0,
                  ),
                ],
              ),
            ),
            if (index < calculationHistory.length - 1)
              const SizedBox(height: 16),
          ],
        ],
        if (widget.showDemoDisclaimer) ...[
          const SizedBox(height: 20),
          const _DemoDisclaimerFooter(),
        ],
      ],
    );
  }
}

Future<void> _showDemoDisclaimerSheet(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            height: screenHeight * 0.74,
            decoration: BoxDecoration(
              color: const Color(0xFF05070A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Demo Notice',
                          style: AppTheme.terminalBody.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 18,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text(
                      demoDisclaimerText,
                      style: AppTheme.terminalBody.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DemoDisclaimerFooter extends StatelessWidget {
  const _DemoDisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDemoDisclaimerSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          demoDisclaimerPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.terminalBody.copyWith(
                            color: Colors.white.withValues(alpha: 0.56),
                            fontSize: 11,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.52),
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
  }
}

class _NotebookSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _NotebookSectionCard({
    required this.title,
    this.subtitle,
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
            Text(
              title,
              style: AppTheme.terminalBody.copyWith(
                color: Colors.amber.withValues(alpha: 0.95),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTheme.terminalBody.copyWith(
                  color: AppTheme.phosphorGreen.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StructuredParagraphText extends StatelessWidget {
  final String text;

  const _StructuredParagraphText({required this.text});

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split('\n\n')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          Text(
            paragraphs[index],
            style: AppTheme.terminalBody,
          ),
          if (index < paragraphs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool positive;

  const _MetricRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.positive = true,
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
            style: TextStyle(
              color: highlight
                  ? (positive
                      ? AppTheme.phosphorGreenBright
                      : Colors.amber.withValues(alpha: 0.95))
                  : AppTheme.phosphorGreenBright,
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

class _CalcField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;

  const _CalcField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.terminalBody.copyWith(
            color: AppTheme.phosphorGreenBright,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Focus(
          onKeyEvent:
              onKeyEvent == null ? null : (_, event) => onKeyEvent!(event),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            style: AppTheme.terminalBody,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppTheme.phosphorGreen.withValues(alpha: 0.8),
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
          ),
        ),
      ],
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  final String message;

  const _EmptySectionMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: AppTheme.terminalBody,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptySectionWithFooter extends StatelessWidget {
  final String message;

  const _EmptySectionWithFooter({required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = (constraints.maxHeight - 16).clamp(240.0, 1200.0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            SizedBox(
              height: contentHeight,
              child: Column(
                children: [
                  const Spacer(),
                  _EmptySectionMessage(message: message),
                  const Spacer(),
                  const _DemoDisclaimerFooter(),
                ],
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
    final answer =
        reflection.answer.trim().isEmpty ? '(No answer)' : reflection.answer;

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
              child: ConstrainedBox(
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
                                      fillColor:
                                          Colors.black.withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppTheme.phosphorGreen
                                              .withValues(alpha: 0.6),
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
                                                    color:
                                                        AppTheme.phosphorGreen,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'SAVE',
                                                  style: TextStyle(
                                                    color: AppTheme
                                                        .phosphorGreenBright,
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
