import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import '../utils/hud_panel_border.dart';
import '../utils/starfield_painter.dart';
import '../utils/grid_overlay_painter.dart';
import '../utils/pixel_route.dart';
import 'end_run_screen.dart';
import 'logbook_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commandFocusNode = FocusNode();
  final List<String> _commandHistory = <String>[];
  bool _handlingPop = false;
  int _lastLogLength = 0;
  int? _historyIndex;
  String _historyDraft = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusCommandInput();
      _scheduleIntroStart();
      _scheduleNarrativeStart();
      unawaited(_endRunIfStuck(context.read<GameProvider>()));
    });
  }

  void _scheduleIntroStart() {
    if (!mounted) return;
    final provider = context.read<GameProvider>();
    if (provider.isIntroActive) {
      // Wait 1-2 seconds before starting the intro
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        provider.startIntroTypewriter();
      });
    }
  }

  void _scheduleNarrativeStart() {
    if (!mounted) return;
    final provider = context.read<GameProvider>();
    if (provider.isNarrativeActive) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        provider.startNarrativeTypewriter();
      });
    }
  }

  Future<void> _endRunIfStuck(GameProvider provider) async {
    if (provider.canContinue()) {
      return;
    }

    provider.notifyGameOver();
    await provider.clearSavedGame();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(pixelRoute(const EndRunScreen()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commandController.dispose();
    _scrollController.dispose();
    _commandFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (!mounted) return;
      unawaited(context.read<GameProvider>().saveGame());
    }

    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _focusCommandInput();
    }
  }

  void _focusCommandInput() {
    if (!_commandFocusNode.canRequestFocus) return;
    FocusScope.of(context).requestFocus(_commandFocusNode);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    if (!mounted) return;
    final provider = context.read<GameProvider>();

    if (provider.isNarrativeActive) {
      return;
    }

    // If intro is active, any input skips it
    if (provider.isIntroActive) {
      provider.skipIntro();
      _commandController.clear();
      _resetHistoryNavigation();
      _focusCommandInput();
      _scrollToBottom();
      await provider.saveGame();
      return;
    }

    _addCommandToHistory(command);

    // Process the command (handles both first choice and normal gameplay)
    if (command.toLowerCase() == 'end') {
      await provider.saveGame();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(pixelRoute(const EndRunScreen()));
      return;
    }

    await provider.processCommand(command);
    if (!mounted) return;
    _commandController.clear();
    _resetHistoryNavigation();
    _focusCommandInput();
    _scrollToBottom();

    await _endRunIfStuck(provider);
  }

  void _addCommandToHistory(String command) {
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
    }
  }

  void _resetHistoryNavigation() {
    _historyIndex = null;
    _historyDraft = '';
  }

  KeyEventResult _onCommandInputKeyEvent(
    KeyEvent event, {
    required bool isIntroActive,
    required bool isNarrativeActive,
  }) {
    if (event is! KeyDownEvent ||
        isIntroActive ||
        isNarrativeActive ||
        _commandHistory.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _navigateCommandHistory(-1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _navigateCommandHistory(1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _navigateCommandHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    if (_historyIndex == null) {
      if (direction > 0) return;
      _historyDraft = _commandController.text;
      _historyIndex = _commandHistory.length - 1;
      _setCommandInput(_commandHistory[_historyIndex!]);
      return;
    }

    final nextIndex = _historyIndex! + direction;
    if (nextIndex < 0) {
      _historyIndex = 0;
      _setCommandInput(_commandHistory[_historyIndex!]);
      return;
    }

    if (nextIndex >= _commandHistory.length) {
      _historyIndex = null;
      _setCommandInput(_historyDraft);
      return;
    }

    _historyIndex = nextIndex;
    _setCommandInput(_commandHistory[_historyIndex!]);
  }

  void _setCommandInput(String value) {
    _commandController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_handlingPop) return;

        _handlingPop = true;
        unawaited(_saveThenPop(result));
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          elevation: 0,
          title: Text('STAR TRAILS', style: AppTheme.appBarTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppTheme.phosphorGreenBright),
            onPressed: () => _confirmExit(context),
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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _focusCommandInput,
          child: Consumer<GameProvider>(
            builder: (context, provider, _) {
              final logLength = provider.state.log.length;
              if (logLength > _lastLogLength) {
                _lastLogLength = logLength;
                _scrollToBottom();
              }

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
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(provider),
                                    _buildHudDivider(),
                                    Expanded(child: _buildLog(provider)),
                                    _buildHudDivider(),
                                    _buildCommandInput(),
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
                  if (provider.showEduPrompt) _buildEduPrompt(provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHudDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        color: AppTheme.phosphorGreenDim.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.phosphorGreen.withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GameProvider provider) {
    final state = provider.state;
    final fuelCapacity = state.getFuelCapacity();
    final cargoCapacity = state.getCargoCapacity();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          if (state.shipName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.shipName.toUpperCase(),
                style: AppTheme.terminalLabel.copyWith(fontSize: 12),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HeaderItem(label: 'LOC', value: state.location),
                    _HeaderItem(
                        label: 'FUEL', value: '${state.fuel}/$fuelCapacity'),
                    _HeaderItem(label: 'CR', value: '${state.credits}'),
                    _HeaderItem(
                        label: 'CARGO', value: '${state.cargoUsed}/$cargoCapacity'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openLogbook,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.phosphorGreenDim.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.phosphorGreen.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'LOGBOOK',
                      style: AppTheme.terminalLabel.copyWith(
                        color: AppTheme.phosphorGreenBright,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLog(GameProvider provider) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: GridOverlayPainter(spacing: 28),
          ),
        ),
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: provider.state.log.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                provider.state.log[index],
                style: AppTheme.terminalBody,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommandInput() {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final isIntroActive = provider.isIntroActive;
        final isNarrativeActive = provider.isNarrativeActive;
        final isInputDisabled = isIntroActive || isNarrativeActive;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTheme.phosphorGreenDim.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text('>', style: AppTheme.terminalPrompt),
              const SizedBox(width: 10),
              Expanded(
                child: Focus(
                  onKeyEvent: (_, event) => _onCommandInputKeyEvent(
                    event,
                    isIntroActive: isIntroActive,
                    isNarrativeActive: isNarrativeActive,
                  ),
                  child: TextField(
                    controller: _commandController,
                    focusNode: _commandFocusNode,
                    autofocus: true,
                    enabled: !isInputDisabled,
                    style: AppTheme.terminalPrompt,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: isIntroActive
                          ? 'Press SKIP to continue'
                          : isNarrativeActive
                              ? 'Narrative in progress'
                              : 'Enter command',
                      hintStyle:
                          const TextStyle(color: AppTheme.phosphorGreenDim),
                    ),
                    onSubmitted: (_) async {
                      await _sendCommand();
                      if (!mounted) return;
                      _focusCommandInput();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isNarrativeActive
                      ? null
                      : () async {
                          if (isIntroActive) {
                            provider.skipIntro();
                            _commandController.clear();
                            _scrollToBottom();
                            await provider.saveGame();
                          } else {
                            await _sendCommand();
                          }
                        },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                      isIntroActive
                          ? 'SKIP'
                          : isNarrativeActive
                              ? 'WAIT'
                              : 'SEND',
                      style: const TextStyle(
                        color: AppTheme.phosphorGreenBright,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
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

  Widget _buildEduPrompt(GameProvider provider) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.phosphorGreenBright.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.phosphorGreen.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.currentEduPrompt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: provider.dismissEduPrompt,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.phosphorGreenDim.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                AppTheme.phosphorGreen.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'GOT IT',
                          style: TextStyle(
                            color: AppTheme.phosphorGreenBright,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final provider = context.read<GameProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Exit to Menu?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress is auto-saved. You can continue later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL',
                style: TextStyle(color: AppTheme.phosphorGreenBright)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('EXIT',
                style: TextStyle(color: AppTheme.phosphorGreenBright)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.saveGame();
      if (!mounted) return;
      navigator.pop();
    }
  }

  Future<void> _saveThenPop(Object? result) async {
    if (!mounted) return;
    await context.read<GameProvider>().saveGame();
    if (!mounted) return;
    Navigator.of(context).pop(result);
    _handlingPop = false;
  }

  void _openLogbook() {
    if (!mounted) return;
    Navigator.of(context).push(pixelRoute(const LogbookScreen()));
  }
}

class _HeaderItem extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.terminalLabel),
        Text(
          value,
          style: AppTheme.terminalBody.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
