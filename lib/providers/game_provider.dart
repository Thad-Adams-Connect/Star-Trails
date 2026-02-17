import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/planet.dart';
import '../models/ship_upgrade.dart';
import '../services/persistence_service.dart';
import '../services/teacher_dashboard_service.dart';
import '../utils/constants.dart';
import '../data/intro_story.dart';

class GameProvider extends ChangeNotifier {
  GameState _state = GameState.initial();
  final PersistenceService _persistence = PersistenceService();
  final TeacherDashboardService _dashboard = TeacherDashboardService();
  bool _sessionIsGameOver = false;
  bool _eduPromptsEnabled = true;
  bool _reflectionEnabled = true;
  bool _showEduPrompt = false;
  String _currentEduPrompt = '';
  bool _saving = false;
  bool _saveQueued = false;
  Future<void>? _saveFuture;
  Timer? _introTimer;
  Timer? _saveThrottleTimer;
  bool _saveThrottled = false;

  GameState get state => _state;
  bool get eduPromptsEnabled => _eduPromptsEnabled;
  bool get reflectionEnabled => _reflectionEnabled;
  bool get showEduPrompt => _showEduPrompt;
  String get currentEduPrompt => _currentEduPrompt;
  TeacherDashboardService get dashboard => _dashboard;
  bool get sessionIsGameOver => _sessionIsGameOver;

  String get _introStoryWithPlayerShipName {
    final shipName = _state.shipName.trim();
    final captainName = _state.captainName.trim();

    var personalizedIntro = introStoryText;

    if (shipName.isNotEmpty) {
      personalizedIntro = personalizedIntro.replaceFirst(
        'Your Ship.\n',
        'Your Ship. $shipName\n',
      );
    }

    if (captainName.isNotEmpty) {
      personalizedIntro = personalizedIntro.replaceFirst(
        'Crew: Just you.\n',
        'Crew: Just you. $captainName\n',
      );
    }

    return personalizedIntro;
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _introTimer = null;
    _saveThrottleTimer?.cancel();
    _saveThrottleTimer = null;
    super.dispose();
  }

  Future<void> loadSettings() async {
    _eduPromptsEnabled = await _persistence.getEduPromptsEnabled();
    _reflectionEnabled = await _persistence.getReflectionEnabled();
    notifyListeners();
  }

  Future<void> setEduPromptsEnabled(bool enabled) async {
    _eduPromptsEnabled = enabled;
    await _persistence.setEduPromptsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setReflectionEnabled(bool enabled) async {
    _reflectionEnabled = enabled;
    await _persistence.setReflectionEnabled(enabled);
    notifyListeners();
  }

  void dismissEduPrompt() {
    _showEduPrompt = false;
    notifyListeners();
  }

  void _maybeShowEduPrompt(String prompt) {
    if (_eduPromptsEnabled) {
      _currentEduPrompt = prompt;
      _showEduPrompt = true;
      notifyListeners();
    }
  }

  Future<bool> loadGame() async {
    await _dashboard.initialize();
    final loadedState = await _persistence.loadGameState();
    if (loadedState != null) {
      _state = loadedState;

      // Sync names from game state to dashboard if needed
      final dashboardData = _dashboard.getData();
      if (_state.captainName.isNotEmpty || _state.shipName.isNotEmpty) {
        if (dashboardData.captainName != _state.captainName ||
            dashboardData.shipName != _state.shipName) {
          await _dashboard.updatePlayerNames(
            captainName: _state.captainName,
            shipName: _state.shipName,
          );
        }
      }

      _sessionIsGameOver = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> startNewGame() async {
    // Clear any UI state from previous game
    _introTimer?.cancel();
    _introTimer = null;
    _showEduPrompt = false;
    _currentEduPrompt = '';

    await _dashboard.initialize();
    await _dashboard.startSession();
    await _persistence.clearGameState();
    _state = GameState.initial();

    // Sync names from dashboard to game state
    final dashboardData = _dashboard.getData();
    final sessionId = _dashboard.getCurrentSessionId();
    _state = _state.copyWith(
      captainName: dashboardData.captainName,
      shipName: dashboardData.shipName,
      currentSessionId: sessionId,
    );

    _sessionIsGameOver = false;
    await saveGame();
    notifyListeners();
  }

  /// Reset session statistics and prepare for the next session.
  /// This is called after ending a session to keep the game running but clear the session stats.
  void resetSessionStats() {
    // Clear any UI state from previous game
    _introTimer?.cancel();
    _introTimer = null;
    _showEduPrompt = false;
    _currentEduPrompt = '';

    _updateState(_state.resetSessionStats());
    _sessionIsGameOver = false;
  }

  /// Update captain and ship names in both GameState and Dashboard.
  Future<void> updatePlayerNames({
    required String captainName,
    required String shipName,
  }) async {
    await _dashboard.updatePlayerNames(
      captainName: captainName,
      shipName: shipName,
    );
    _updateState(_state.copyWith(
      captainName: captainName,
      shipName: shipName,
    ));
  }

  /// Update the current session ID in game state.
  void updateSessionId(String sessionId) {
    _updateState(_state.copyWith(currentSessionId: sessionId));
  }

  void clearSessionGameOver() {
    _sessionIsGameOver = false;
  }

  Future<void> clearSavedGame() async {
    await _persistence.clearGameState();
  }

  /// Persist current state. Safe to call repeatedly; skips if a save is already in progress.
  Future<void> saveGame() async {
    if (_saving) {
      _saveQueued = true;
      return _saveFuture ?? Future<void>.value();
    }

    _saving = true;
    _saveFuture = _runSaveLoop();
    try {
      await _saveFuture;
    } finally {
      _saveFuture = null;
      _saving = false;
    }
  }

  Future<void> _runSaveLoop() async {
    do {
      _saveQueued = false;
      final snapshot = _state;
      await _persistence.saveGameState(snapshot);
    } while (_saveQueued);
  }

  /// Update state and trigger autosave. Use this for all state changes to ensure data is persisted.
  void _updateState(GameState newState,
      {bool notify = true, bool throttleSave = false}) {
    _state = newState;
    if (notify) {
      notifyListeners();
    }

    // Fire and forget autosave - don't await to keep UI responsive
    if (throttleSave) {
      // For high-frequency updates (like intro typewriter), throttle saves to max once per 500ms
      if (!_saveThrottled) {
        _saveThrottled = true;
        saveGame();
        _saveThrottleTimer?.cancel();
        _saveThrottleTimer = Timer(const Duration(milliseconds: 500), () {
          _saveThrottled = false;
        });
      }
    } else {
      // For normal operations, save immediately
      saveGame();
    }
  }

  void _addLog(String message) {
    final newLog = List<String>.from(_state.log)..add(message);
    _updateState(_state.copyWith(log: newLog), notify: false);
  }

  /// Process a command and persist state. Callers should await this so save completes before navigation.
  Future<void> processCommand(String input) async {
    final parts = input.trim().toLowerCase().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) {
      _addLog('Enter a command. Type "help" for options.');
      notifyListeners();
      return;
    }

    // Handle first choice if active
    if (_state.firstChoiceActive) {
      await _handleFirstChoice(input.trim());
      await saveGame();
      notifyListeners();
      return;
    }

    final command = parts[0];

    switch (command) {
      case 'help':
        _handleHelp();
        break;
      case 'status':
        _handleStatus();
        break;
      case 'market':
        _handleMarket(parts);
        break;
      case 'cargo':
        _handleCargo();
        break;
      case 'buy':
        _handleBuy(parts);
        break;
      case 'sell':
        _handleSell(parts);
        break;
      case 'refuel':
        _handleRefuel(parts);
        break;
      case 'upgrade':
        _handleUpgrade(parts);
        break;
      case 'travel':
        _handleTravel(parts);
        break;
      case 'end':
        _handleEnd();
        break;
      default:
        _addLog('Unknown command: $command. Type "help" for options.');
    }

    // Ensure any queued saves complete before returning
    await saveGame();
    notifyListeners();
  }

  void _handleHelp() {
    _addLog('');
    _addLog('COMMANDS:');
    _addLog('  help - show this help');
    _addLog('  status - show your status');
    _addLog(
        '  market [system] - show market prices (current system or specified system)');
    _addLog('  cargo - show your cargo');
    _addLog('  buy <item> <qty> - buy items (must be docked)');
    _addLog('  sell <item> <qty> - sell items (must be docked)');
    _addLog('  refuel <qty> - buy fuel (must be docked)');
    _addLog('  upgrade <type> <tier> - upgrade ship (fuel or cargo)');
    _addLog('  travel <system> - travel to system');
    _addLog('  end - end current run');
    _addLog('');
    _addLog('SYSTEMS: ${GameConstants.planetIds.join(", ")}');
    _addLog('ITEMS: ${GameConstants.itemIds.join(", ")}');
    _addLog('');
  }

  void _handleStatus() {
    final cargoCapacity = _state.getCargoCapacity();
    final fuelCapacity = _state.getFuelCapacity();
    _addLog('');
    if (_state.captainName.isNotEmpty) {
      _addLog('CAPTAIN: ${_state.captainName}');
    }
    if (_state.shipName.isNotEmpty) {
      _addLog('SHIP: ${_state.shipName}');
    }
    _addLog('LOCATION: ${_state.location}');
    _addLog('FUEL: ${_state.fuel}/$fuelCapacity');
    _addLog('CREDITS: ${_state.credits}');
    _addLog('CARGO: ${_state.cargoUsed}/$cargoCapacity');
    _addLog('');
    _addLog(_state.currentPlanet.getDescription());
    _addLog('');
  }

  void _handleMarket(List<String> parts) {
    late String systemId;
    late Planet planet;

    if (parts.length < 2) {
      // No system specified, show current system
      systemId = _state.location;
      planet = _state.currentPlanet;
    } else {
      // System specified, look it up
      final systemInput = parts.skip(1).join(' ').toUpperCase();
      if (!GameConstants.planetIds.contains(systemInput)) {
        _addLog('Unknown system: $systemInput');
        _addLog('Systems: ${GameConstants.planetIds.join(", ")}');
        return;
      }
      systemId = systemInput;
      planet = _state.planets[systemId]!;
    }

    _addLog('');
    _addLog('MARKET at $systemId:');
    _addLog('');
    for (var item in GameConstants.itemIds) {
      final bid = planet.getBidPrice(item);
      final ask = planet.getAskPrice(item);
      _addLog('  $item: BUY at $ask cr, SELL at $bid cr');
    }
    _addLog('');
    _addLog('FUEL: ${planet.getFuelPrice()} cr/unit');
    if (systemId != _state.location) {
      _addLog('[View only - you are not docked at this system]');
    }
    _addLog('');
  }

  void _handleCargo() {
    final cargoCapacity = _state.getCargoCapacity();
    _addLog('');
    _addLog('CARGO (${_state.cargoUsed}/$cargoCapacity):');
    for (var item in GameConstants.itemIds) {
      final qty = _state.cargo[item]!;
      _addLog('  $item: $qty');
    }
    _addLog('');
  }

  void _handleBuy(List<String> parts) {
    if (parts.length < 3) {
      _addLog('Usage: buy <item> <qty>');
      return;
    }

    // Verify you are docked to buy
    if (_state.location.isEmpty) {
      _addLog('You must be docked to buy items.');
      return;
    }

    final itemInput = parts[1];
    final item = _findItem(itemInput);
    if (item == null) {
      _addLog('Unknown item: $itemInput');
      return;
    }

    final qty = int.tryParse(parts[2]);
    if (qty == null || qty <= 0) {
      _addLog('Invalid quantity: ${parts[2]}');
      return;
    }

    final cargoCapacity = _state.getCargoCapacity();
    if (_state.cargoAvailable < qty) {
      _addLog(
          'Not enough cargo space. Available: ${_state.cargoAvailable}/$cargoCapacity');
      return;
    }

    final planet = _state.currentPlanet;
    final askPrice = planet.getAskPrice(item);
    final totalCost = askPrice * qty;

    if (_state.credits < totalCost) {
      _addLog('Not enough credits. Need: $totalCost, Have: ${_state.credits}');
      return;
    }

    final newCredits = _state.credits - totalCost;
    final newCargo = Map<String, int>.from(_state.cargo);
    newCargo[item] = newCargo[item]! + qty;

    _updateState(
        _state.copyWith(
          credits: newCredits,
          cargo: newCargo,
          totalCreditsSpentOnGoods: _state.totalCreditsSpentOnGoods + totalCost,
        ),
        notify: false);

    _addLog('');
    _addLog('Bought $qty $item for $totalCost cr ($askPrice cr each).');
    _addLog('Credits remaining: $newCredits');
    _addLog('');

    unawaited(_dashboard.recordTradeCompleted());

    _maybeShowEduPrompt(
        'You bought $item at $askPrice credits each. Can you find a planet where you can sell it for more?');
  }

  void _handleSell(List<String> parts) {
    if (parts.length < 3) {
      _addLog('Usage: sell <item> <qty>');
      return;
    }

    // Verify you are docked to sell
    if (_state.location.isEmpty) {
      _addLog('You must be docked to sell items.');
      return;
    }

    final itemInput = parts[1];
    final item = _findItem(itemInput);
    if (item == null) {
      _addLog('Unknown item: $itemInput');
      return;
    }

    final qty = int.tryParse(parts[2]);
    if (qty == null || qty <= 0) {
      _addLog('Invalid quantity: ${parts[2]}');
      return;
    }

    if (_state.cargo[item]! < qty) {
      _addLog('Not enough $item in cargo. Have: ${_state.cargo[item]}');
      return;
    }

    final planet = _state.currentPlanet;
    final bidPrice = planet.getBidPrice(item);
    final totalEarned = bidPrice * qty;

    final newCredits = _state.credits + totalEarned;
    final newCargo = Map<String, int>.from(_state.cargo);
    newCargo[item] = newCargo[item]! - qty;

    final newPlanets = Map<String, Planet>.from(_state.planets);
    newPlanets[_state.location] = planet.decreaseDemand(item);

    _updateState(
        _state.copyWith(
          credits: newCredits,
          cargo: newCargo,
          planets: newPlanets,
          totalCreditsEarned: _state.totalCreditsEarned + totalEarned,
        ),
        notify: false);

    _addLog('');
    _addLog('Sold $qty $item for $totalEarned cr ($bidPrice cr each).');
    _addLog('Credits: $newCredits');
    _addLog('');

    unawaited(_dashboard.recordTradeCompleted());

    _maybeShowEduPrompt(
        'Selling items decreases demand. If you sell more of the same item here, you might get less for it next time!');
  }

  void _handleRefuel(List<String> parts) {
    if (parts.length < 2) {
      _addLog('Usage: refuel <qty>');
      return;
    }

    // Verify you are docked to refuel
    if (_state.location.isEmpty) {
      _addLog('You must be docked to refuel.');
      return;
    }

    final qty = int.tryParse(parts[1]);
    if (qty == null || qty <= 0) {
      _addLog('Invalid quantity: ${parts[1]}');
      return;
    }

    final planet = _state.currentPlanet;
    final fuelPrice = planet.getFuelPrice();
    final totalCost = fuelPrice * qty;

    if (_state.credits < totalCost) {
      _addLog('Not enough credits. Need: $totalCost, Have: ${_state.credits}');
      return;
    }

    final fuelCapacity = _state.getFuelCapacity();
    final maxCanBuy = fuelCapacity - _state.fuel;
    if (maxCanBuy <= 0) {
      _addLog('Fuel tank is full. Capacity: $fuelCapacity');
      return;
    }

    final qtyToBuy = qty > maxCanBuy ? maxCanBuy : qty;
    final actualCost = fuelPrice * qtyToBuy;

    final newCredits = _state.credits - actualCost;
    final newFuel = _state.fuel + qtyToBuy;

    _updateState(
        _state.copyWith(
          credits: newCredits,
          fuel: newFuel,
          totalCreditsSpentOnFuel: _state.totalCreditsSpentOnFuel + actualCost,
        ),
        notify: false);

    _addLog('');
    _addLog('Bought $qtyToBuy fuel for $actualCost cr ($fuelPrice cr each).');
    _addLog('Fuel: $newFuel/$fuelCapacity, Credits: $newCredits');
    if (qtyToBuy < qty) {
      _addLog('(Could only buy $qtyToBuy; tank capacity is $fuelCapacity)');
    }
    _addLog('');
  }

  void _handleTravel(List<String> parts) {
    if (parts.length < 2) {
      _addLog('Usage: travel <planet>');
      _addLog('Planets: ${GameConstants.planetIds.join(", ")}');
      return;
    }

    // Join remaining parts to handle multi-word planet names
    final destInput = parts.skip(1).join(' ').toUpperCase();
    if (!GameConstants.planetIds.contains(destInput)) {
      _addLog('Unknown planet: $destInput');
      _addLog('Planets: ${GameConstants.planetIds.join(", ")}');
      return;
    }

    if (destInput == _state.location) {
      _addLog('You are already at $destInput.');
      return;
    }

    final fuelCost = GameConstants.travelCosts[_state.location]![destInput]!;
    if (_state.fuel < fuelCost) {
      _addLog('Not enough fuel. Need: $fuelCost, Have: ${_state.fuel}');
      return;
    }

    final newFuel = _state.fuel - fuelCost;
    final newPlanets = Map<String, Planet>.from(_state.planets);
    newPlanets[destInput] = newPlanets[destInput]!.increaseDemandAll();

    _updateState(
        _state.copyWith(
          location: destInput,
          fuel: newFuel,
          planets: newPlanets,
          totalFuelUsed: _state.totalFuelUsed + fuelCost,
        ),
        notify: false);

    _addLog('');
    _addLog('Traveled to $destInput. Used $fuelCost fuel.');
    _addLog('Fuel remaining: $newFuel');
    _addLog('');
    _addLog(_state.currentPlanet.getDescription());
    _addLog('');

    _maybeShowEduPrompt(
        'Traveling uses fuel and restores demand at your destination. Plan your route to maximize profit!');
  }

  void _handleUpgrade(List<String> parts) {
    if (parts.length < 3) {
      _addLog('Usage: upgrade <type> <tier>');
      _addLog('Types: fuel, cargo');
      _addLog('Tiers: 0 (Base), 1 (Tier 1), 2 (Tier 2)');
      _addLog('');
      _showUpgradeStatus();
      return;
    }

    final typeInput = parts[1].toLowerCase();
    final tierInput = int.tryParse(parts[2]);

    if (typeInput != 'fuel' && typeInput != 'cargo') {
      _addLog('Unknown upgrade type: $typeInput (use "fuel" or "cargo")');
      return;
    }

    if (tierInput == null || tierInput < 0 || tierInput > 2) {
      _addLog('Invalid tier: ${parts[2]} (use 0, 1, or 2)');
      return;
    }

    final currentUpgrade = _state.shipUpgrades[typeInput]!;

    if (currentUpgrade.currentTier == tierInput) {
      _addLog('Already at $typeInput tier $tierInput');
      return;
    }

    if (tierInput < currentUpgrade.currentTier) {
      _addLog('Cannot downgrade. Current: tier ${currentUpgrade.currentTier}');
      return;
    }

    final cost = GameConstants.getUpgradeCost(typeInput, tierInput);
    if (_state.credits < cost) {
      _addLog('Not enough credits. Need: $cost, Have: ${_state.credits}');
      return;
    }

    final newCredits = _state.credits - cost;
    final newUpgrades = Map<String, ShipUpgrade>.from(_state.shipUpgrades);
    newUpgrades[typeInput] =
        ShipUpgrade(type: typeInput, currentTier: tierInput);

    _updateState(
        _state.copyWith(
          credits: newCredits,
          shipUpgrades: newUpgrades,
          totalCreditsSpentOnUpgrades:
              _state.totalCreditsSpentOnUpgrades + cost,
        ),
        notify: false);

    final tierName = GameConstants.upgradeTiers[tierInput].name;
    final capacity = GameConstants.upgradeTiers[tierInput].capacity;

    _addLog('');
    _addLog('Upgraded $typeInput to $tierName!');
    _addLog('New capacity: $capacity');
    _addLog('Credits: $newCredits');
    _addLog('');

    _maybeShowEduPrompt(
        'You upgraded your ship! Higher capacity helps you carry more and travel further.');
  }

  void _showUpgradeStatus() {
    _addLog('');
    _addLog('SHIP UPGRADES:');
    for (final upgradeType in ['fuel', 'cargo']) {
      final upgrade = _state.shipUpgrades[upgradeType]!;
      final tierName = GameConstants.upgradeTiers[upgrade.currentTier].name;
      final capacity = GameConstants.upgradeTiers[upgrade.currentTier].capacity;
      _addLog('  $upgradeType: $tierName ($capacity capacity)');

      if (upgrade.currentTier < 2) {
        final nextTier = upgrade.currentTier + 1;
        final nextTierName = GameConstants.upgradeTiers[nextTier].name;
        final nextCapacity = GameConstants.upgradeTiers[nextTier].capacity;
        final nextCost = GameConstants.getUpgradeCost(upgradeType, nextTier);
        _addLog('    -> $nextTierName ($nextCapacity capacity): $nextCost cr');
      }
    }
    _addLog('');
  }

  void _handleEnd() {
    _addLog('');
    _addLog(
        'Session ended. Review your progress and reflections on the next screen.');
    _addLog('');
  }

  /// Called when the player runs out of trading options.
  void notifyGameOver() {
    _sessionIsGameOver = true;
  }

  /// Handle the first gameplay choice after intro (A, B, or C).
  Future<void> _handleFirstChoice(String input) async {
    final choice = input.toUpperCase();

    if (choice != 'A' && choice != 'B' && choice != 'C') {
      _addLog('Please type A, B, or C to make your first choice.');
      return;
    }

    // Deactivate first choice mode
    _updateState(_state.copyWith(firstChoiceActive: false), notify: false);

    _addLog('');
    _addLog('> $choice');
    _addLog('');

    switch (choice) {
      case 'A':
        // Buy safe items and make a short trip
        _addLog('You decide to play it safe.');
        _addLog('');
        _addLog('You buy 5 Food Packs for 500 credits.');
        _addLog('These are easy to sell anywhere.');
        _addLog('');

        // Buy 5 food packs
        final newCredits = _state.credits - 500;
        final newCargo = Map<String, int>.from(_state.cargo);
        newCargo['Food'] = (newCargo['Food'] ?? 0) + 5;

        _updateState(
            _state.copyWith(
              credits: newCredits,
              cargo: newCargo,
              totalCreditsSpentOnGoods: _state.totalCreditsSpentOnGoods + 500,
            ),
            notify: false);

        _addLog('Short trips mean less risk and lower fuel costs.');
        _addLog('You can always expand your routes later.');
        _addLog('');
        break;

      case 'B':
        // Spend more on medical kits and travel farther
        _addLog('You decide to invest more for a bigger payoff.');
        _addLog('');
        _addLog('You buy 3 Medical Kits for 900 credits.');
        _addLog('Medical supplies are valuable on the frontier.');
        _addLog('');

        // Buy 3 medical kits
        final newCredits = _state.credits - 900;
        final newCargo = Map<String, int>.from(_state.cargo);
        newCargo['Medicine'] = (newCargo['Medicine'] ?? 0) + 3;

        _updateState(
            _state.copyWith(
              credits: newCredits,
              cargo: newCargo,
              totalCreditsSpentOnGoods: _state.totalCreditsSpentOnGoods + 900,
            ),
            notify: false);

        _addLog('Frontier colonies pay well for scarce supplies.');
        _addLog('But remember: longer trips need more fuel.');
        _addLog('');
        break;

      case 'C':
        // Look at prices first
        _addLog('Smart! Always check the market before buying.');
        _addLog('');
        _addLog('You study the market data carefully.');
        _addLog('');
        _addLog('Food Packs are cheap and easy to move.');
        _addLog('Medical Kits cost more but sell for higher profit.');
        _addLog('Raw Ore prices vary a lot between systems.');
        _addLog('Energy Cells are steady but low margin.');
        _addLog('');
        _addLog('Understanding supply and demand is key to success.');
        _addLog('You can use the "market" command anytime to check prices.');
        _addLog('');
        break;
    }

    _addLog('You are now in command of your ship.');
    _addLog('Type "help" to see available commands.');
    _addLog('Type "status" to check your situation.');
    _addLog('Type "market" to see current prices.');
    _addLog('');
    _addLog('Good luck, Captain!');
    _addLog('');
  }

  /// Start the intro typewriter sequence.
  void startIntroTypewriter() {
    _introTimer?.cancel();
    _scheduleNextIntroCharacter();
  }

  void _scheduleNextIntroCharacter(
      [Duration delay = const Duration(milliseconds: 50)]) {
    _introTimer = Timer(delay, () {
      if (!isIntroActive) {
        _introTimer?.cancel();
        _introTimer = null;
        return;
      }

      final introText = _introStoryWithPlayerShipName;

      if (_state.introCharIndex >= introText.length) {
        _introTimer?.cancel();
        _introTimer = null;
        completeIntro();
        notifyListeners();
        return;
      }

      final nextChar = introText[_state.introCharIndex];
      final hasMore = addNextIntroCharacter();
      notifyListeners();

      if (!hasMore) {
        // Intro finished, show the first choice
        _introTimer?.cancel();
        _introTimer = null;
        completeIntro();
        notifyListeners();
        return;
      }

      final nextDelay = nextChar == '\n'
          ? const Duration(milliseconds: 700)
          : const Duration(milliseconds: 50);
      _scheduleNextIntroCharacter(nextDelay);
    });
  }

  /// Add the next character of the intro story to the log.
  /// Returns true if there are more characters to display, false if intro is complete.
  bool addNextIntroCharacter() {
    final introText = _introStoryWithPlayerShipName;

    if (_state.introCharIndex >= introText.length) {
      return false; // Intro is complete
    }

    final nextChar = introText[_state.introCharIndex];

    // Get the current last line or create a new one
    List<String> newLog = List<String>.from(_state.log);
    if (newLog.isEmpty) {
      newLog.add('');
    }

    // Handle newlines by adding a new log entry
    if (nextChar == '\n') {
      newLog.add('');
    } else {
      // Append the character to the last log line
      newLog[newLog.length - 1] = newLog[newLog.length - 1] + nextChar;
    }

    _updateState(
        _state.copyWith(
          log: newLog,
          introCharIndex: _state.introCharIndex + 1,
        ),
        notify: false,
        throttleSave: true);

    // Check if we've reached the end
    if (_state.introCharIndex >= introText.length) {
      return false; // Last character was just added
    }
    return true;
  }

  /// Complete the intro immediately and show the first choice.
  void completeIntro() {
    final introText = _introStoryWithPlayerShipName;

    // Add any remaining characters from the intro story
    while (_state.introCharIndex < introText.length) {
      addNextIntroCharacter();
    }

    // End intro and activate first choice
    _updateState(
        _state.copyWith(
          isIntroActive: false,
          firstChoiceActive: true,
        ),
        notify: false);
    _addLog('');

    // Ensure final intro state is saved
    saveGame();
  }

  /// Skip the intro and show the first choice immediately.
  void skipIntro() {
    _introTimer?.cancel();
    _introTimer = null;
    completeIntro();
    notifyListeners();
  }

  /// Check if the intro is currently active.
  bool get isIntroActive => _state.isIntroActive;

  String? _findItem(String input) {
    final lower = input.toLowerCase();
    for (var item in GameConstants.itemIds) {
      if (item.toLowerCase() == lower) {
        return item;
      }
    }
    return null;
  }

  bool _canBuyAnyItem() {
    if (_state.cargoAvailable <= 0) {
      return false;
    }

    final planet = _state.currentPlanet;
    for (final item in GameConstants.itemIds) {
      if (_state.credits >= planet.getAskPrice(item)) {
        return true;
      }
    }
    return false;
  }

  bool _canSellAnyCargo() {
    for (final item in GameConstants.itemIds) {
      if ((_state.cargo[item] ?? 0) > 0) {
        return true;
      }
    }
    return false;
  }

  bool _canRefuel() {
    final fuelCapacity = _state.getFuelCapacity();
    if (_state.fuel >= fuelCapacity) {
      return false;
    }

    final fuelPrice = _state.currentPlanet.getFuelPrice();
    return _state.credits >= fuelPrice;
  }

  bool _canTravelAnywhere() {
    final routes = GameConstants.travelCosts[_state.location];
    if (routes == null) {
      return false;
    }

    for (final entry in routes.entries) {
      if (entry.key != _state.location && _state.fuel >= entry.value) {
        return true;
      }
    }
    return false;
  }

  bool _canUpgradeAnything() {
    for (final type in ['fuel', 'cargo']) {
      final currentTier = _state.shipUpgrades[type]?.currentTier ?? 0;
      if (currentTier >= 2) {
        continue;
      }

      final nextTier = currentTier + 1;
      final cost = GameConstants.getUpgradeCost(type, nextTier);
      if (_state.credits >= cost) {
        return true;
      }
    }
    return false;
  }

  bool canContinue() {
    if (_state.isIntroActive || _state.firstChoiceActive) {
      return true;
    }

    return _canBuyAnyItem() ||
        _canSellAnyCargo() ||
        _canRefuel() ||
        _canTravelAnywhere() ||
        _canUpgradeAnything();
  }
}
