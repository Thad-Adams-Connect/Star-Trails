import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/planet.dart';
import '../models/ship_upgrade.dart';
import '../services/persistence_service.dart';
import '../services/teacher_dashboard_service.dart';
import '../utils/constants.dart';
import '../data/intro_story.dart';
import '../data/system_histories.dart';

class GameProvider extends ChangeNotifier {
  static const Duration _introCharDelay = Duration(milliseconds: 80);
  static const Duration _introLineDelay = Duration(milliseconds: 750);
  static const Duration _introSectionDelay = Duration(milliseconds: 750);
  static const Duration _introHeadingDelay = Duration(milliseconds: 1200);
  static const Set<String> _introMajorHeadings = <String>{
    'Your Ship',
    'What You Know',
    'Market Snapshot — Helios Reach',
    'Your First Choice',
  };

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
  Timer? _narrativeTimer;
  Timer? _saveThrottleTimer;
  bool _saveThrottled = false;
  String? _pendingNarrativeSystemId;

  GameState get state => _state;
  bool get eduPromptsEnabled => _eduPromptsEnabled;
  bool get reflectionEnabled => _reflectionEnabled;
  bool get showEduPrompt => _showEduPrompt;
  String get currentEduPrompt => _currentEduPrompt;
  TeacherDashboardService get dashboard => _dashboard;
  bool get sessionIsGameOver => _sessionIsGameOver;
  bool get isNarrativeActive => _state.isNarrativeActive;

  String get _introStoryWithPlayerShipName {
    final shipName = _state.shipName.trim();
    final captainName = _state.captainName.trim();
    final resolvedShipName =
        shipName.isNotEmpty ? shipName : 'Opportunity for ship name';
    final resolvedCaptainName =
        captainName.isNotEmpty ? captainName : 'Opportunity for name';

    var personalizedIntro = introStoryText;

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
  void dispose() {
    _introTimer?.cancel();
    _introTimer = null;
    _narrativeTimer?.cancel();
    _narrativeTimer = null;
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
    _tryStartPendingNarrative();
  }

  void _maybeShowEduPrompt(String prompt) {
    if (_eduPromptsEnabled && !_state.isNarrativeActive) {
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
    _narrativeTimer?.cancel();
    _narrativeTimer = null;
    _pendingNarrativeSystemId = null;
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
    _narrativeTimer?.cancel();
    _narrativeTimer = null;
    _pendingNarrativeSystemId = null;
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
      case 'trip':
        _handleTrip(parts);
        break;
      case 'ship':
        _handleShip(parts);
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
    _addLog('  market - show market prices at current location');
    _addLog('  cargo - show your cargo');
    _addLog('  buy <item> <qty> - buy items (must be docked)');
    _addLog('  sell <item> <qty> - sell items (must be docked)');
    _addLog('  refuel <qty> - buy fuel (must be docked)');
    
    // Build dynamic upgrade types list based on unlocks
    final upgradeTypes = <String>['fuel', 'cargo'];
    if (GameConstants.isComputerUpgradeUnlocked(_state.credits)) {
      upgradeTypes.add('computer');
    }
    if (GameConstants.isEngineUpgradeUnlocked(_state.credits)) {
      upgradeTypes.add('engine');
    }
    _addLog('  upgrade <type> <tier> - upgrade ship (${upgradeTypes.join(", ")})');
    _addLog('  travel <system> - travel to system');
    
    final computerTier = _state.getComputerTier();
    if (computerTier >= 1) {
      _addLog('  trip <system> - show fuel required to destination');
    }
    if (computerTier >= 2) {
      _addLog('  market <system> - show market at remote system');
    }
    
    if (GameConstants.isClassCShipUnlocked(_state.credits) && _state.shipClass == 'CLASS-B') {
      _addLog('  ship buy - purchase CLASS-C ship (at HELIOS REACH)');
    }
    
    _addLog('  end - end current run');
    _addLog('');
    
    // Show only unlocked systems and commodities
    final availableSystems = GameConstants.getAvailableSystems(_state.credits);
    final availableCommodities = GameConstants.getAvailableCommodities(_state.credits);
    
    _addLog('SYSTEMS: ${availableSystems.join(", ")}');
    _addLog('ITEMS: ${availableCommodities.join(", ")}');
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
    // Check if trying to view remote market
    if (parts.length >= 2) {
      final computerTier = _state.getComputerTier();
      if (computerTier < 2) {
        _addLog('Remote market viewing requires Computer Tier 2.');
        _addLog('Upgrade your computer system to access this feature.');
        _addLog('Currently showing market at your docked location only.');
        _addLog('');
      } else {
        // Computer T2 unlocked, allow remote viewing
        final systemInput = parts.skip(1).join(' ').toUpperCase();
        
        if (!GameConstants.planetIds.contains(systemInput)) {
          _addLog('Unknown system: $systemInput');
          final availableSystems = GameConstants.getAvailableSystems(_state.credits);
          _addLog('Available systems: ${availableSystems.join(", ")}');
          return;
        }
        
        // Check if system is unlocked
        if (!GameConstants.isSystemUnlocked(systemInput, _state.credits)) {
          _addLog('System $systemInput is not yet unlocked.');
          return;
        }
        
        // Show remote market
        final planet = _state.planets[systemInput]!;
        _addLog('');
        _addLog('MARKET at $systemInput:');
        _addLog('');
        
        final availableCommodities = GameConstants.getAvailableCommodities(_state.credits);
        for (var item in availableCommodities) {
          final baseAsk = planet.getAskPrice(item);
          final baseBid = planet.getBidPrice(item);
          _addLog('  $item: BUY at $baseAsk cr, SELL at $baseBid cr');
        }
        _addLog('');
        _addLog('FUEL: ${planet.getFuelPrice()} cr/unit');
        _addLog('[Remote viewing - you are not docked at this system]');
        _addLog('');
        return;
      }
    }

    // Show current docked system market
    final systemId = _state.location;
    final planet = _state.currentPlanet;

    _addLog('');
    _addLog('MARKET at $systemId:');
    _addLog('');
    
    final availableCommodities = GameConstants.getAvailableCommodities(_state.credits);
    for (var item in availableCommodities) {
      final baseAsk = planet.getAskPrice(item);
      final baseBid = planet.getBidPrice(item);
      
      // Apply route adjustments for current system
      final ask = _getAdjustedPrice(systemId, item, true, baseAsk);
      final bid = _getAdjustedPrice(systemId, item, false, baseBid);
      
      _addLog('  $item: BUY at $ask cr, SELL at $bid cr');
    }
    _addLog('');
    _addLog('FUEL: ${planet.getFuelPrice()} cr/unit');
    _addLog('');
  }

  void _handleCargo() {
    final cargoCapacity = _state.getCargoCapacity();
    _addLog('');
    _addLog('CARGO (${_state.cargoUsed}/$cargoCapacity):');
    
    final availableCommodities = GameConstants.getAvailableCommodities(_state.credits);
    for (var item in availableCommodities) {
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
    
    // Check if commodity is unlocked
    if (!GameConstants.isCommodityUnlocked(item, _state.credits)) {
      _addLog('$item is not yet unlocked.');
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
    final baseAskPrice = planet.getAskPrice(item);
    
    // Apply route exploit control pricing
    final askPrice = _getAdjustedPrice(_state.location, item, true, baseAskPrice);
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
    if (askPrice != baseAskPrice) {
      _addLog('(Market adjusted from base price of $baseAskPrice cr)');
    }
    _addLog('Credits remaining: $newCredits');
    _addLog('');
    
    // Record route usage for exploit control
    _recordRouteUsage(_state.location, item);

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
    
    // Check if commodity is unlocked
    if (!GameConstants.isCommodityUnlocked(item, _state.credits)) {
      _addLog('$item is not yet unlocked.');
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
    final baseBidPrice = planet.getBidPrice(item);
    
    // Apply route exploit control pricing
    final bidPrice = _getAdjustedPrice(_state.location, item, false, baseBidPrice);
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
    if (bidPrice != baseBidPrice) {
      _addLog('(Market adjusted from base price of $baseBidPrice cr)');
    }
    _addLog('Credits: $newCredits');
    _addLog('');
    
    // Record route usage for exploit control
    _recordRouteUsage(_state.location, item);
    
    // Check and update unlocks based on new credit balance
    _checkAndUpdateUnlocks();

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
      final availableSystems = GameConstants.getAvailableSystems(_state.credits);
      _addLog('Available systems: ${availableSystems.join(", ")}');
      return;
    }

    // Join remaining parts to handle multi-word planet names
    final destInput = parts.skip(1).join(' ').toUpperCase();
    
    // Check if system exists
    if (!GameConstants.planetIds.contains(destInput)) {
      _addLog('Unknown planet: $destInput');
      final availableSystems = GameConstants.getAvailableSystems(_state.credits);
      _addLog('Available systems: ${availableSystems.join(", ")}');
      return;
    }
    
    // Check if system is unlocked
    if (!GameConstants.isSystemUnlocked(destInput, _state.credits)) {
      _addLog('System $destInput is not yet unlocked.');
      _addLog('Continue trading to unlock new systems!');
      return;
    }

    if (destInput == _state.location) {
      _addLog('You are already at $destInput.');
      return;
    }

    // Calculate fuel cost with engine upgrades applied
    final engineTier = _state.getEngineTier();
    final fuelCost = GameConstants.calculateFuelCost(_state.location, destInput, engineTier);
    
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
    if (engineTier > 0) {
      _addLog('(Engine upgrade reduced fuel cost by $engineTier)');
    }
    _addLog('Fuel remaining: $newFuel');
    _addLog('');
    _addLog(_state.currentPlanet.getDescription());
    _addLog('');

    _maybeShowEduPrompt(
        'Traveling uses fuel and restores demand at your destination. Plan your route to maximize profit!');
    _queueSystemHistoryIfFirstVisit(destInput);
  }

  void _handleUpgrade(List<String> parts) {
    if (parts.length < 3) {
      _addLog('Usage: upgrade <type> <tier>');
      
      // Build list of available upgrade types based on unlocks
      final availableTypes = <String>['fuel', 'cargo'];
      if (GameConstants.isComputerUpgradeUnlocked(_state.credits)) {
        availableTypes.add('computer');
      }
      if (GameConstants.isEngineUpgradeUnlocked(_state.credits)) {
        availableTypes.add('engine');
      }
      
      _addLog('Types: ${availableTypes.join(", ")}');
      _addLog('Tiers: 0 (Base), 1 (Tier 1), 2 (Tier 2)');
      _addLog('');
      _showUpgradeStatus();
      return;
    }

    final typeInput = parts[1].toLowerCase();
    final tierInput = int.tryParse(parts[2]);

    // Build list of valid types based on unlocks
    final validTypes = <String>['fuel', 'cargo'];
    if (GameConstants.isComputerUpgradeUnlocked(_state.credits)) {
      validTypes.add('computer');
    }
    if (GameConstants.isEngineUpgradeUnlocked(_state.credits)) {
      validTypes.add('engine');
    }
    
    // Validate upgrade type
    if (!validTypes.contains(typeInput)) {
      _addLog('Unknown upgrade type: $typeInput');
      _addLog('Valid types: ${validTypes.join(", ")}');
      return;
    }

    if (tierInput == null || tierInput < 0 || tierInput > 2) {
      _addLog('Invalid tier: ${parts[2]} (use 0, 1, or 2)');
      return;
    }

    if (_state.location != 'HELIOS REACH') {
      _addLog('Upgrades are only available at HELIOS REACH.');
      return;
    }
    
    // Check if upgrading CLASS-C ship (which can't upgrade fuel/cargo)
    if (_state.shipClass == 'CLASS-C' && (typeInput == 'fuel' || typeInput == 'cargo')) {
      _addLog('CLASS-C ship has fixed fuel and cargo capacity.');
      _addLog('Fuel and Cargo upgrades are not available for this ship class.');
      return;
    }
    
    // Check if upgrading CLASS-C ship's computer (already has T1+T2)
    if (_state.shipClass == 'CLASS-C' && typeInput == 'computer') {
      _addLog('CLASS-C ship includes Computer T1 and T2 by default.');
      _addLog('No further computer upgrades available.');
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

    _addLog('');
    _addLog('Upgraded $typeInput to Tier $tierInput!');
    
    // Show type-specific upgrade benefit
    if (typeInput == 'fuel' || typeInput == 'cargo') {
      final capacity = GameConstants.upgradeTiers[tierInput].capacity;
      _addLog('New capacity: $capacity');
    } else if (typeInput == 'computer') {
      _addLog(GameConstants.computerUpgradeDescriptions[tierInput]!);
      if (tierInput == 1) {
        _addLog('Use: trip <system>');
      } else if (tierInput == 2) {
        _addLog('Use: market <system>');
      }
    } else if (typeInput == 'engine') {
      _addLog(GameConstants.engineUpgradeDescriptions[tierInput]!);
    }
    
    _addLog('Credits: $newCredits');
    _addLog('');

    _maybeShowEduPrompt(
        'You upgraded your ship! Higher capacity helps you carry more and travel further.');
  }

  void _showUpgradeStatus() {
    _addLog('');
    _addLog('SHIP: ${_state.shipClass}');
    _addLog('');
    _addLog('SHIP UPGRADES:');
    
    // Show fuel and cargo for CLASS-B
    if (_state.shipClass == 'CLASS-B') {
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
    } else {
      // CLASS-C has fixed capacity
      final shipSpec = GameConstants.shipSpecs[_state.shipClass]!;
      _addLog('  fuel: Fixed (${shipSpec.fuelCapacity} capacity)');
      _addLog('  cargo: Fixed (${shipSpec.cargoCapacity} capacity)');
    }
    
    // Show computer upgrades only if unlocked
    if (GameConstants.isComputerUpgradeUnlocked(_state.credits)) {
      final computerTier = _state.getComputerTier();
      _addLog('  computer: Tier $computerTier');
      _addLog('    ${GameConstants.computerUpgradeDescriptions[computerTier]!}');
      
      if (_state.shipClass != 'CLASS-C' && computerTier < 2) {
        final nextTier = computerTier + 1;
        final nextCost = GameConstants.getUpgradeCost('computer', nextTier);
        _addLog('    -> Tier $nextTier: $nextCost cr');
        _addLog('       ${GameConstants.computerUpgradeDescriptions[nextTier]!}');
      }
    }
    
    // Show engine upgrades only if unlocked
    if (GameConstants.isEngineUpgradeUnlocked(_state.credits)) {
      final engineTier = _state.getEngineTier();
      _addLog('  engine: Tier $engineTier');
      _addLog('    ${GameConstants.engineUpgradeDescriptions[engineTier]!}');
      
      if (engineTier < 2) {
        final nextTier = engineTier + 1;
        final nextCost = GameConstants.getUpgradeCost('engine', nextTier);
        _addLog('    -> Tier $nextTier: $nextCost cr');
        _addLog('       ${GameConstants.engineUpgradeDescriptions[nextTier]!}');
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
        final planetA = _state.currentPlanet;
        const foodQty = 5;
        const foodItem = 'Food';
        final foodUnitPrice = planetA.getAskPrice(foodItem);
        final foodTotalCost = foodUnitPrice * foodQty;
        _addLog('You buy $foodQty Food Packs for $foodTotalCost credits.');
        _addLog('These are easy to sell anywhere.');
        _addLog('');

        // Buy 5 food packs
        final newCredits = _state.credits - foodTotalCost;
        final newCargo = Map<String, int>.from(_state.cargo);
        newCargo[foodItem] = (newCargo[foodItem] ?? 0) + foodQty;

        _updateState(
            _state.copyWith(
              credits: newCredits,
              cargo: newCargo,
              totalCreditsSpentOnGoods:
                  _state.totalCreditsSpentOnGoods + foodTotalCost,
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
        final planetB = _state.currentPlanet;
        const medQty = 6;
        const medItem = 'Medicine';
        final medUnitPrice = planetB.getAskPrice(medItem);
        final medTotalCost = medUnitPrice * medQty;
        _addLog('You buy $medQty Medical Kits for $medTotalCost credits.');
        _addLog('Medical supplies are valuable on the frontier.');
        _addLog('');

        // Buy 3 medical kits
        final newCredits = _state.credits - medTotalCost;
        final newCargo = Map<String, int>.from(_state.cargo);
        newCargo[medItem] = (newCargo[medItem] ?? 0) + medQty;

        _updateState(
            _state.copyWith(
              credits: newCredits,
              cargo: newCargo,
              totalCreditsSpentOnGoods:
                  _state.totalCreditsSpentOnGoods + medTotalCost,
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

    if (_state.location == 'HELIOS REACH') {
      _queueSystemHistoryIfFirstVisit(_state.location);
    }
  }

  /// Start the intro typewriter sequence.
  void startIntroTypewriter() {
    _introTimer?.cancel();
    _scheduleNextIntroCharacter();
  }

  void _scheduleNextIntroCharacter(
      [Duration delay = _introCharDelay]) {
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

      final nextDelay = _nextIntroDelay(introText, _state.introCharIndex - 1);
      _scheduleNextIntroCharacter(nextDelay);
    });
  }

  Duration _nextIntroDelay(String introText, int charIndexJustTyped) {
    if (charIndexJustTyped < 0 || charIndexJustTyped >= introText.length) {
      return _introCharDelay;
    }

    final typedChar = introText[charIndexJustTyped];
    if (typedChar != '\n') {
      return _introCharDelay;
    }

    final completedLine =
        _lineEndingAtNewline(introText, charIndexJustTyped).trimRight();
    if (_introMajorHeadings.contains(completedLine)) {
      return _introHeadingDelay;
    }

    if (completedLine.isEmpty) {
      return _introSectionDelay;
    }

    return _introLineDelay;
  }

  String _lineEndingAtNewline(String text, int newlineIndex) {
    final lineStart = text.lastIndexOf('\n', newlineIndex - 1) + 1;
    return text.substring(lineStart, newlineIndex);
  }

  bool _appendTypewriterCharacter({
    required String fullText,
    required int currentIndex,
    required void Function(List<String> log, int nextIndex) applyUpdate,
  }) {
    if (currentIndex >= fullText.length) {
      return false;
    }

    final nextChar = fullText[currentIndex];
    final newLog = List<String>.from(_state.log);
    if (newLog.isEmpty) {
      newLog.add('');
    }

    if (nextChar == '\n') {
      newLog.add('');
    } else {
      newLog[newLog.length - 1] = newLog[newLog.length - 1] + nextChar;
    }

    applyUpdate(newLog, currentIndex + 1);

    if (currentIndex + 1 >= fullText.length) {
      return false;
    }
    return true;
  }

  /// Add the next character of the intro story to the log.
  /// Returns true if there are more characters to display, false if intro is complete.
  bool addNextIntroCharacter() {
    final introText = _introStoryWithPlayerShipName;
    return _appendTypewriterCharacter(
      fullText: introText,
      currentIndex: _state.introCharIndex,
      applyUpdate: (newLog, nextIndex) {
        _updateState(
            _state.copyWith(
              log: newLog,
              introCharIndex: nextIndex,
            ),
            notify: false,
            throttleSave: true);
      },
    );
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

  /// Start or resume a system history narrative typewriter sequence.
  void startNarrativeTypewriter() {
    if (!_state.isNarrativeActive) {
      return;
    }

    if (_showEduPrompt || isIntroActive) {
      return;
    }

    _narrativeTimer?.cancel();
    _prepareLogForNarrative();
    _scheduleNextNarrativeCharacter();
  }

  void _scheduleNextNarrativeCharacter(
      [Duration delay = _introCharDelay]) {
    _narrativeTimer = Timer(delay, () {
      if (!isNarrativeActive) {
        _narrativeTimer?.cancel();
        _narrativeTimer = null;
        return;
      }

      final historyText = _activeNarrativeText;
      if (historyText == null || historyText.isEmpty) {
        _completeSystemHistoryNarrative();
        notifyListeners();
        return;
      }

      if (_state.narrativeCharIndex >= historyText.length) {
        _completeSystemHistoryNarrative();
        notifyListeners();
        return;
      }

      final hasMore = _addNextNarrativeCharacter(historyText);
      notifyListeners();

      if (!hasMore) {
        _completeSystemHistoryNarrative();
        notifyListeners();
        return;
      }

      final nextDelay =
          _nextIntroDelay(historyText, _state.narrativeCharIndex - 1);
      _scheduleNextNarrativeCharacter(nextDelay);
    });
  }

  String? get _activeNarrativeText {
    final systemId = _state.narrativeSystemId.trim();
    if (systemId.isEmpty) {
      return null;
    }
    return innerRingSystemHistories[systemId] ?? outerSystemHistories[systemId];
  }

  bool _addNextNarrativeCharacter(String historyText) {
    return _appendTypewriterCharacter(
      fullText: historyText,
      currentIndex: _state.narrativeCharIndex,
      applyUpdate: (newLog, nextIndex) {
        _updateState(
            _state.copyWith(
              log: newLog,
              narrativeCharIndex: nextIndex,
            ),
            notify: false,
            throttleSave: true);
      },
    );
  }

  void _completeSystemHistoryNarrative() {
    final systemId = _state.narrativeSystemId;

    final updatedFirstVisit = Map<String, bool>.from(_state.systemFirstVisit);
    if (systemId.isNotEmpty) {
      updatedFirstVisit[systemId] = false;
    }

    _updateState(
        _state.copyWith(
          isNarrativeActive: false,
          narrativeCharIndex: 0,
          narrativeSystemId: '',
          systemFirstVisit: updatedFirstVisit,
        ),
        notify: false);

    if (systemId.isNotEmpty) {
      final sessionId = _state.currentSessionId.isNotEmpty
          ? _state.currentSessionId
          : _dashboard.getCurrentSessionId();
      if (sessionId.isNotEmpty) {
        unawaited(_dashboard.addSystemEntry(
          sessionId: sessionId,
          systemId: systemId,
          historyText: 'System Entered',
        ));
      }
    }

    saveGame();
  }

  void _queueSystemHistoryIfFirstVisit(String systemId) {
    final normalized = systemId.trim().toUpperCase();
    final isFirstVisit = _state.systemFirstVisit[normalized] ?? true;
    if (!isFirstVisit) {
      return;
    }

    // Check both Inner Ring and outer system histories
    final hasHistory = innerRingSystemHistories.containsKey(normalized) ||
                      outerSystemHistories.containsKey(normalized);
    if (!hasHistory) {
      return;
    }

    _pendingNarrativeSystemId = normalized;
    _tryStartPendingNarrative();
  }

  void _tryStartPendingNarrative() {
    if (_pendingNarrativeSystemId == null) {
      return;
    }

    if (isIntroActive || isNarrativeActive || _showEduPrompt) {
      return;
    }

    final systemId = _pendingNarrativeSystemId!;
    _pendingNarrativeSystemId = null;
    _startSystemHistoryNarrative(systemId);
  }

  void _startSystemHistoryNarrative(String systemId) {
    // Check both Inner Ring and outer system histories
    final historyText = innerRingSystemHistories[systemId] ?? outerSystemHistories[systemId];
    if (historyText == null || historyText.isEmpty) {
      return;
    }

    _narrativeTimer?.cancel();
    _prepareLogForNarrative();
    _updateState(
        _state.copyWith(
          isNarrativeActive: true,
          narrativeCharIndex: 0,
          narrativeSystemId: systemId,
        ),
        notify: true);
    _scheduleNextNarrativeCharacter();
  }

  void _prepareLogForNarrative() {
    if (_state.narrativeCharIndex > 0) {
      return;
    }
    final newLog = List<String>.from(_state.log);
    newLog.add('');
    newLog.add('');
    _updateState(_state.copyWith(log: newLog), notify: false);
  }

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
    if (_state.isIntroActive ||
        _state.firstChoiceActive ||
        _state.isNarrativeActive) {
      return true;
    }

    return _canBuyAnyItem() ||
        _canSellAnyCargo() ||
        _canRefuel() ||
        _canTravelAnywhere() ||
        _canUpgradeAnything();
  }
  
  /// Check and update unlock flags based on current credit balance
  void _checkAndUpdateUnlocks() {
    final currentCredits = _state.credits;
    bool updated = false;
    bool tier1 = _state.tier1Unlocked;
    bool tier2 = _state.tier2Unlocked;
    bool tier3 = _state.tier3Unlocked;
    bool tier4 = _state.tier4Unlocked;
    
    // Check each tier - once unlocked, stays unlocked
    if (!tier1 && currentCredits >= GameConstants.unlockTier1Credits) {
      tier1 = true;
      updated = true;
      _addLog('');
      _addLog('═══ ACHIEVEMENT UNLOCKED ═══');
      _addLog('Credit Balance: ${GameConstants.unlockTier1Credits}+');
      _addLog('');
      _addLog('NEW SYSTEMS:');
      _addLog('  • Orivault Complex');
      _addLog('  • Candescent Yard');
      _addLog('');
      _addLog('NEW COMMODITY:');
      _addLog('  • Tech');
      _addLog('');
      _addLog('NEW UPGRADE PATH:');
      _addLog('  • Computer (use "upgrade computer <tier>")');
      _addLog('    - Tier 1: TRIP command (${GameConstants.upgradeCosts['computer']![1]} cr)');
      _addLog('    - Tier 2: MARKET command (${GameConstants.upgradeCosts['computer']![2]} cr)');
      _addLog('════════════════════════════');
      _addLog('');
    }
    
    if (!tier2 && currentCredits >= GameConstants.unlockTier2Credits) {
      tier2 = true;
      updated = true;
      _addLog('');
      _addLog('═══ ACHIEVEMENT UNLOCKED ═══');
      _addLog('Credit Balance: ${GameConstants.unlockTier2Credits}+');
      _addLog('');
      _addLog('NEW SYSTEMS:');
      _addLog('  • Fluxhaven Institute');
      _addLog('  • Velaris Enclave');
      _addLog('');
      _addLog('NEW COMMODITY:');
      _addLog('  • Luxury');
      _addLog('');
      _addLog('NEW UPGRADE PATH:');
      _addLog('  • Engine (use "upgrade engine <tier>")');
      _addLog('    - Tier 1: -1 fuel per trip (${GameConstants.upgradeCosts['engine']![1]} cr)');
      _addLog('    - Tier 2: -2 fuel per trip (${GameConstants.upgradeCosts['engine']![2]} cr)');
      _addLog('════════════════════════════');
      _addLog('');
    }
    
    if (!tier3 && currentCredits >= GameConstants.unlockTier3Credits) {
      tier3 = true;
      updated = true;
      _addLog('');
      _addLog('═══ ACHIEVEMENT UNLOCKED ═══');
      _addLog('Credit Balance: ${GameConstants.unlockTier3Credits}+');
      _addLog('');
      _addLog('NEW SYSTEMS:');
      _addLog('  • Gateforge Bastion');
      _addLog('  • Redhaven Anchorpoint');
      _addLog('');
      _addLog('NEW SHIP AVAILABLE:');
      final classCSpec = GameConstants.shipSpecs['CLASS-C']!;
      _addLog('  • CLASS-C Ship (${classCSpec.baseCost} cr)');
      _addLog('    - ${classCSpec.fuelCapacity} Fuel Capacity');
      _addLog('    - ${classCSpec.cargoCapacity} Cargo Capacity');
      _addLog('    - Includes Computer T1+T2');
      _addLog('    - Purchase at HELIOS REACH: "buy ship"');
      _addLog('════════════════════════════');
      _addLog('');
    }
    
    if (!tier4 && currentCredits >= GameConstants.unlockTier4Credits) {
      tier4 = true;
      updated = true;
      _addLog('');
      _addLog('═══ ACHIEVEMENT UNLOCKED ═══');
      _addLog('Credit Balance: ${GameConstants.unlockTier4Credits}+');
      _addLog('');
      _addLog('NEW SYSTEMS:');
      _addLog('  • Startrail Expanse');
      _addLog('  • Outercrest Nexus');
      _addLog('');
      _addLog('Full 12-system map now available!');
      _addLog('════════════════════════════');
      _addLog('');
    }
    
    if (updated) {
      _updateState(_state.copyWith(
        tier1Unlocked: tier1,
        tier2Unlocked: tier2,
        tier3Unlocked: tier3,
        tier4Unlocked: tier4,
      ), notify: false);
    }
  }
  
  /// Track route usage for exploit control
  /// Returns adjusted price (may be modified from base price)
  int _getAdjustedPrice(String system, String commodity, bool isBuying, int basePrice) {
    // Create route identifier (sorted alphabetically)
    final routeKey = _makeRouteKey(system, commodity);
    
    final usageCount = _state.routeUsage[routeKey] ?? 0;
    
    // First few uses: no price impact
    if (usageCount < GameConstants.routeFreeUses) {
      return basePrice;
    }
    
    // After that, every N additional executions: ±X% price change
    final excessUses = usageCount - (GameConstants.routeFreeUses - 1);
    final priceAdjustments = excessUses ~/ GameConstants.routeUsesPerAdjustment;
    
    if (priceAdjustments <= 0) {
      return basePrice;
    }
    
    // Calculate cumulative percentage changes
    double adjustedPrice = basePrice.toDouble();
    final adjustmentMultiplier = 1.0 + (isBuying ? GameConstants.routePriceAdjustmentPercent : -GameConstants.routePriceAdjustmentPercent);
    
    for (int i = 0; i < priceAdjustments; i++) {
      adjustedPrice *= adjustmentMultiplier;
    }
    
    return adjustedPrice.round();
  }
  
  /// Record a trade on a route
  void _recordRouteUsage(String system, String commodity) {
    final routeKey = _makeRouteKey(system, commodity);
    
    final newUsage = Map<String, int>.from(_state.routeUsage);
    newUsage[routeKey] = (newUsage[routeKey] ?? 0) + 1;
    
    // Reset recovery counter for this route
    final newRecovery = Map<String, int>.from(_state.routeRecoveryCounter);
    newRecovery[routeKey] = 0;
    
    // Increment recovery counters for all OTHER routes
    for (final key in newRecovery.keys) {
      if (key != routeKey) {
        newRecovery[key] = (newRecovery[key] ?? 0) + 1;
        
        // If a route hasn't been used for N different trades, recover some uses
        if (newRecovery[key]! >= GameConstants.routeRecoveryThreshold) {
          newRecovery[key] = 0;
          if (newUsage.containsKey(key) && newUsage[key]! > 0) {
            newUsage[key] = (newUsage[key]! - GameConstants.routeRecoveryAmount).clamp(0, 999);
          }
        }
      }
    }
    
    _updateState(_state.copyWith(
      routeUsage: newUsage,
      routeRecoveryCounter: newRecovery,
    ), notify: false);
  }
  
  String _makeRouteKey(String system, String commodity) {
    return '$system->$commodity';
  }
  
  void _handleTrip(List<String> parts) {
    // Requires Computer T1 or higher
    final computerTier = _state.getComputerTier();
    if (computerTier < 1) {
      _addLog('TRIP command requires Computer Tier 1.');
      _addLog('Upgrade your computer system to access this feature.');
      return;
    }
    
    if (parts.length < 2) {
      _addLog('Usage: trip <system>');
      final availableSystems = GameConstants.getAvailableSystems(_state.credits);
      _addLog('Available systems: ${availableSystems.join(", ")}');
      return;
    }
    
    final destInput = parts.skip(1).join(' ').toUpperCase();
    
    if (!GameConstants.planetIds.contains(destInput)) {
      _addLog('Unknown system: $destInput');
      final availableSystems = GameConstants.getAvailableSystems(_state.credits);
      _addLog('Available systems: ${availableSystems.join(", ")}');
      return;
    }
    
    if (!GameConstants.isSystemUnlocked(destInput, _state.credits)) {
      _addLog('System $destInput is not yet unlocked.');
      return;
    }
    
    if (destInput == _state.location) {
      _addLog('You are already at $destInput.');
      return;
    }
    
    final engineTier = _state.getEngineTier();
    final fuelCost = GameConstants.calculateFuelCost(_state.location, destInput, engineTier);
    
    _addLog('');
    _addLog('TRIP CALCULATION:');
    _addLog('From: ${_state.location}');
    _addLog('To: $destInput');
    _addLog('Fuel required: $fuelCost');
    if (engineTier > 0) {
      final baseCost = GameConstants.travelCosts[_state.location]![destInput]!;
      _addLog('(Base cost: $baseCost, reduced by $engineTier with engine upgrade)');
    }
    _addLog('Current fuel: ${_state.fuel}');
    if (_state.fuel >= fuelCost) {
      _addLog('Status: SUFFICIENT FUEL');
    } else {
      final needed = fuelCost - _state.fuel;
      _addLog('Status: INSUFFICIENT (need $needed more)');
    }
    _addLog('');
  }
  
  void _handleShip(List<String> parts) {
    if (parts.length < 2) {
      // Show current ship info
      _addLog('');
      _addLog('CURRENT SHIP: ${_state.shipClass}');
      final shipSpec = GameConstants.shipSpecs[_state.shipClass]!;
      _addLog(shipSpec.description);
      _addLog('Fuel Capacity: ${shipSpec.fuelCapacity}');
      _addLog('Cargo Capacity: ${shipSpec.cargoCapacity}');
      
      if (_state.shipClass == 'CLASS-B' && GameConstants.isClassCShipUnlocked(_state.credits)) {
        _addLog('');
        _addLog('AVAILABLE FOR PURCHASE:');
        final classCSpec = GameConstants.shipSpecs['CLASS-C']!;
        _addLog('CLASS-C Ship - ${classCSpec.baseCost} cr');
        _addLog('  ${classCSpec.description}');
        _addLog('  Fuel: ${classCSpec.fuelCapacity}');
        _addLog('  Cargo: ${classCSpec.cargoCapacity}');
        _addLog('  Resale value: ${classCSpec.resaleValue} cr');
        _addLog('  Use "ship buy" at HELIOS REACH to purchase');
      }
      _addLog('');
      return;
    }
    
    final action = parts[1].toLowerCase();
    
    if (action == 'buy') {
      // Purchase CLASS-C ship
      if (!GameConstants.isClassCShipUnlocked(_state.credits)) {
        _addLog('CLASS-C ship unlocks at ${GameConstants.unlockTier3Credits} credits.');
        return;
      }
      
      if (_state.shipClass == 'CLASS-C') {
        _addLog('You already own a CLASS-C ship.');
        return;
      }
      
      if (_state.location != 'HELIOS REACH') {
        _addLog('Ships can only be purchased at HELIOS REACH.');
        return;
      }
      
      final classCSpec = GameConstants.shipSpecs['CLASS-C']!;
      final classBSpec = GameConstants.shipSpecs['CLASS-B']!;
      
      // Cost is purchase price minus resale of current ship (which is 0 for CLASS-B)
      final netCost = classCSpec.baseCost - classBSpec.resaleValue;
      
      if (_state.credits < netCost) {
        _addLog('Not enough credits. Need: $netCost, Have: ${_state.credits}');
        return;
      }
      
      // Check if cargo would overflow
      if (_state.cargoUsed > classCSpec.cargoCapacity) {
        _addLog('Cannot switch ships: current cargo (${_state.cargoUsed}) exceeds CLASS-C capacity (${classCSpec.cargoCapacity}).');
        _addLog('Sell some cargo before purchasing.');
        return;
      }
      
      final newCredits = _state.credits - netCost;
      final newFuel = _state.fuel.clamp(0, classCSpec.fuelCapacity);
      
      // CLASS-C includes Computer T1+T2 by default
      final newUpgrades = Map<String, ShipUpgrade>.from(_state.shipUpgrades);
      newUpgrades['computer'] = ShipUpgrade(type: 'computer', currentTier: 2);
      
      _updateState(_state.copyWith(
        shipClass: 'CLASS-C',
        fuel: newFuel,
        credits: newCredits,
        shipUpgrades: newUpgrades,
        totalCreditsSpentOnUpgrades: _state.totalCreditsSpentOnUpgrades + netCost,
      ), notify: false);
      
      _addLog('');
      _addLog('═══════════════════════════');
      _addLog('SHIP PURCHASE COMPLETE');
      _addLog('═══════════════════════════');
      _addLog('New ship: CLASS-C');
      _addLog('Fuel capacity: ${classCSpec.fuelCapacity}');
      _addLog('Cargo capacity: ${classCSpec.cargoCapacity}');
      _addLog('Integrated systems: Computer T1+T2');
      _addLog('');
      _addLog('Credits remaining: $newCredits');
      _addLog('═══════════════════════════');
      _addLog('');
      
      _maybeShowEduPrompt(
          'You upgraded to a CLASS-C ship! This powerful vessel gives you more capacity and includes advanced computer systems.');
    } else {
      _addLog('Unknown ship command: $action');
      _addLog('Use "ship" to view info or "ship buy" to purchase.');
    }
  }
}
