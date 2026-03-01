// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'planet.dart';
import 'ship_upgrade.dart';
import 'cr_access_state.dart';
import '../utils/constants.dart';

class GameState {
  final String location;
  final int fuel;
  final int credits;
  final int highestCreditsReached;
  final Map<String, int> cargo;
  final Map<String, Planet> planets;
  final List<String> log;

  // Ship upgrades: Map<type, ShipUpgrade> where type is "fuel", "cargo", "computer", "engine"
  final Map<String, ShipUpgrade> shipUpgrades;

  // Current ship class
  final String shipClass; // 'CLASS-B' or 'CLASS-C'

  // CR access states: Map<access_level_number, CRAccessState>
  // Key: "1", "2", "3", "4" (access level number as string)
  // discovered: permanent once reached, accessActive: dynamic based on hysteresis
  final Map<String, CRAccessState> tierAccessStates;

  // Route exploit control: tracks route usage
  // Key: "SYSTEM_A->SYSTEM_B->COMMODITY" (sorted alphabetically by system)
  // Value: number of times this route has been used
  final Map<String, int> routeUsage;

  // Tracks number of different trades since last route usage (for recovery)
  // Key: route identifier (same format as routeUsage)
  // Value: number of different trades since last use
  final Map<String, int> routeRecoveryCounter;

  // Run/Session statistics (reset at end of each session)
  final int totalFuelUsed;
  final int totalCreditsSpentOnFuel;
  final int totalCreditsSpentOnGoods;
  final int totalCreditsSpentOnUpgrades;
  final int totalCreditsEarned;

  // Lifetime statistics (persist across sessions)
  final int lifetimeFuelUsed;
  final int lifetimeCreditsSpentOnFuel;
  final int lifetimeCreditsSpentOnGoods;
  final int lifetimeCreditsSpentOnUpgrades;
  final int lifetimeCreditsEarned;

  // Intro sequence state
  final bool isIntroActive;
  final int introCharIndex; // Position in the intro story being typed
  final bool
      firstChoiceActive; // After intro, player must make first gameplay choice

  // System history narrative state
  final bool isNarrativeActive;
  final int narrativeCharIndex;
  final String narrativeSystemId;
  final String currentNarrativeText; // The full text being displayed
  final Map<String, bool> systemFirstVisit;

  // Player identity
  final String captainName;
  final String shipName;
  final String currentSessionId;

  GameState({
    required this.location,
    required this.fuel,
    required this.credits,
    int? highestCreditsReached,
    required this.cargo,
    required this.planets,
    required this.log,
    required this.shipUpgrades,
    this.shipClass = 'CLASS-B',
    Map<String, CRAccessState>? tierAccessStates,
    Map<String, int>? routeUsage,
    Map<String, int>? routeRecoveryCounter,
    this.captainName = '',
    this.shipName = '',
    this.currentSessionId = '',
    this.totalFuelUsed = 0,
    this.totalCreditsSpentOnFuel = 0,
    this.totalCreditsSpentOnGoods = 0,
    this.totalCreditsSpentOnUpgrades = 0,
    this.totalCreditsEarned = 0,
    this.lifetimeFuelUsed = 0,
    this.lifetimeCreditsSpentOnFuel = 0,
    this.lifetimeCreditsSpentOnGoods = 0,
    this.lifetimeCreditsSpentOnUpgrades = 0,
    this.lifetimeCreditsEarned = 0,
    this.isIntroActive = false,
    this.introCharIndex = 0,
    this.firstChoiceActive = false,
    this.isNarrativeActive = false,
    this.narrativeCharIndex = 0,
    this.narrativeSystemId = '',
    this.currentNarrativeText = '',
    Map<String, bool>? systemFirstVisit,
  })  : systemFirstVisit = systemFirstVisit ?? const {},
        highestCreditsReached = highestCreditsReached ?? credits,
        tierAccessStates = tierAccessStates ??
            const {
              '1': CRAccessState(discovered: false, accessActive: false),
              '2': CRAccessState(discovered: false, accessActive: false),
              '3': CRAccessState(discovered: false, accessActive: false),
              '4': CRAccessState(discovered: false, accessActive: false),
            },
        routeUsage = routeUsage ?? const {},
        routeRecoveryCounter = routeRecoveryCounter ?? const {};

  factory GameState.initial() {
    final planets = <String, Planet>{};
    for (var planetId in GameConstants.planetIds) {
      planets[planetId] = Planet(id: planetId);
    }

    final cargo = <String, int>{};
    for (var itemId in GameConstants.itemIds) {
      cargo[itemId] = 0;
    }

    final shipUpgrades = <String, ShipUpgrade>{
      'fuel': ShipUpgrade.initial('fuel'),
      'cargo': ShipUpgrade.initial('cargo'),
      'computer': ShipUpgrade.initial('computer'),
      'engine': ShipUpgrade.initial('engine'),
    };

    return GameState(
      location: GameConstants.initialLocation,
      fuel: GameConstants.initialFuel,
      credits: GameConstants.initialCredits,
      cargo: cargo,
      planets: planets,
      log: [],
      shipUpgrades: shipUpgrades,
      shipClass: 'CLASS-B',
      tierAccessStates: const {
        '1': CRAccessState(discovered: false, accessActive: false),
        '2': CRAccessState(discovered: false, accessActive: false),
        '3': CRAccessState(discovered: false, accessActive: false),
        '4': CRAccessState(discovered: false, accessActive: false),
      },
      captainName: '',
      shipName: '',
      currentSessionId: '',
      isIntroActive: true,
      introCharIndex: 0,
      firstChoiceActive: false,
      isNarrativeActive: false,
      narrativeCharIndex: 0,
      narrativeSystemId: '',
      currentNarrativeText: '',
      systemFirstVisit: {
        for (final planetId in GameConstants.planetIds) planetId: true,
      },
    );
  }

  int get cargoUsed {
    return cargo.values.fold(0, (sum, qty) => sum + qty);
  }

  int get cargoAvailable {
    return getCargoCapacity() - cargoUsed;
  }

  /// Get the current fuel capacity based on ship class and upgrades.
  int getFuelCapacity() {
    final shipSpec = GameConstants.shipSpecs[shipClass]!;

    // For CLASS-C, use ship's base capacity (not affected by fuel upgrades)
    if (shipClass == 'CLASS-C') {
      return shipSpec.fuelCapacity;
    }

    // For CLASS-B, use upgrade tier capacity
    final fuelUpgrade = shipUpgrades['fuel']!;
    return GameConstants.upgradeTiers[fuelUpgrade.currentTier].capacity;
  }

  /// Get the current cargo capacity based on ship class and upgrades.
  int getCargoCapacity() {
    final shipSpec = GameConstants.shipSpecs[shipClass]!;

    // For CLASS-C, use ship's base capacity (not affected by cargo upgrades)
    if (shipClass == 'CLASS-C') {
      return shipSpec.cargoCapacity;
    }

    // For CLASS-B, use upgrade tier capacity
    final cargoUpgrade = shipUpgrades['cargo']!;
    return GameConstants.upgradeTiers[cargoUpgrade.currentTier].capacity;
  }

  /// Get the current computer tier, accounting for ship class
  int getComputerTier() {
    // CLASS-C includes Computer T1 and T2 by default
    if (shipClass == 'CLASS-C') {
      return 2;
    }

    // Otherwise use upgrade tier
    final computerUpgrade = shipUpgrades['computer'];
    return computerUpgrade?.currentTier ?? 0;
  }

  /// Get the current engine tier
  int getEngineTier() {
    final engineUpgrade = shipUpgrades['engine'];
    return engineUpgrade?.currentTier ?? 0;
  }

  Planet get currentPlanet => planets[location]!;

  int get unlockedLevel =>
      GameConstants.getUnlockedLevelForHighestCredits(highestCreditsReached);

  bool get reachedFinalCreditMilestone =>
      highestCreditsReached >= GameConstants.finalCreditMilestone;

  GameState copyWith({
    String? location,
    int? fuel,
    int? credits,
    int? highestCreditsReached,
    Map<String, int>? cargo,
    Map<String, Planet>? planets,
    List<String>? log,
    Map<String, ShipUpgrade>? shipUpgrades,
    String? shipClass,
    Map<String, CRAccessState>? tierAccessStates,
    Map<String, int>? routeUsage,
    Map<String, int>? routeRecoveryCounter,
    String? captainName,
    String? shipName,
    String? currentSessionId,
    int? totalFuelUsed,
    int? totalCreditsSpentOnFuel,
    int? totalCreditsSpentOnGoods,
    int? totalCreditsSpentOnUpgrades,
    int? totalCreditsEarned,
    int? lifetimeFuelUsed,
    int? lifetimeCreditsSpentOnFuel,
    int? lifetimeCreditsSpentOnGoods,
    int? lifetimeCreditsSpentOnUpgrades,
    int? lifetimeCreditsEarned,
    bool? isIntroActive,
    int? introCharIndex,
    bool? firstChoiceActive,
    bool? isNarrativeActive,
    int? narrativeCharIndex,
    String? narrativeSystemId,
    String? currentNarrativeText,
    Map<String, bool>? systemFirstVisit,
  }) {
    final resolvedCredits = credits ?? this.credits;
    final resolvedHighestCredits =
        (highestCreditsReached ?? this.highestCreditsReached) > resolvedCredits
            ? (highestCreditsReached ?? this.highestCreditsReached)
            : resolvedCredits;

    return GameState(
      location: location ?? this.location,
      fuel: fuel ?? this.fuel,
      credits: resolvedCredits,
      highestCreditsReached: resolvedHighestCredits,
      cargo: cargo ?? Map<String, int>.from(this.cargo),
      planets: planets ?? Map<String, Planet>.from(this.planets),
      log: log ?? List<String>.from(this.log),
      shipUpgrades:
          shipUpgrades ?? Map<String, ShipUpgrade>.from(this.shipUpgrades),
      shipClass: shipClass ?? this.shipClass,
      tierAccessStates: tierAccessStates ??
          Map<String, CRAccessState>.from(this.tierAccessStates),
      routeUsage: routeUsage ?? Map<String, int>.from(this.routeUsage),
      routeRecoveryCounter: routeRecoveryCounter ??
          Map<String, int>.from(this.routeRecoveryCounter),
      captainName: captainName ?? this.captainName,
      shipName: shipName ?? this.shipName,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      totalFuelUsed: totalFuelUsed ?? this.totalFuelUsed,
      totalCreditsSpentOnFuel:
          totalCreditsSpentOnFuel ?? this.totalCreditsSpentOnFuel,
      totalCreditsSpentOnGoods:
          totalCreditsSpentOnGoods ?? this.totalCreditsSpentOnGoods,
      totalCreditsSpentOnUpgrades:
          totalCreditsSpentOnUpgrades ?? this.totalCreditsSpentOnUpgrades,
      totalCreditsEarned: totalCreditsEarned ?? this.totalCreditsEarned,
      lifetimeFuelUsed: lifetimeFuelUsed ?? this.lifetimeFuelUsed,
      lifetimeCreditsSpentOnFuel:
          lifetimeCreditsSpentOnFuel ?? this.lifetimeCreditsSpentOnFuel,
      lifetimeCreditsSpentOnGoods:
          lifetimeCreditsSpentOnGoods ?? this.lifetimeCreditsSpentOnGoods,
      lifetimeCreditsSpentOnUpgrades:
          lifetimeCreditsSpentOnUpgrades ?? this.lifetimeCreditsSpentOnUpgrades,
      lifetimeCreditsEarned:
          lifetimeCreditsEarned ?? this.lifetimeCreditsEarned,
      isIntroActive: isIntroActive ?? this.isIntroActive,
      introCharIndex: introCharIndex ?? this.introCharIndex,
      firstChoiceActive: firstChoiceActive ?? this.firstChoiceActive,
      isNarrativeActive: isNarrativeActive ?? this.isNarrativeActive,
      narrativeCharIndex: narrativeCharIndex ?? this.narrativeCharIndex,
      narrativeSystemId: narrativeSystemId ?? this.narrativeSystemId,
      currentNarrativeText: currentNarrativeText ?? this.currentNarrativeText,
      systemFirstVisit:
          systemFirstVisit ?? Map<String, bool>.from(this.systemFirstVisit),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'fuel': fuel,
      'credits': credits,
      'highestCreditsReached': highestCreditsReached,
      'cargo': cargo,
      'planets': planets.map((k, v) => MapEntry(k, v.toJson())),
      'log': log,
      'shipUpgrades': shipUpgrades.map((k, v) => MapEntry(k, v.toJson())),
      'shipClass': shipClass,
      'tierAccessStates': tierAccessStates.map(
          (k, v) => MapEntry(k, v.toJson())),
      'routeUsage': routeUsage,
      'routeRecoveryCounter': routeRecoveryCounter,
      'captainName': captainName,
      'shipName': shipName,
      'currentSessionId': currentSessionId,
      'totalFuelUsed': totalFuelUsed,
      'totalCreditsSpentOnFuel': totalCreditsSpentOnFuel,
      'totalCreditsSpentOnGoods': totalCreditsSpentOnGoods,
      'totalCreditsSpentOnUpgrades': totalCreditsSpentOnUpgrades,
      'totalCreditsEarned': totalCreditsEarned,
      'lifetimeFuelUsed': lifetimeFuelUsed,
      'lifetimeCreditsSpentOnFuel': lifetimeCreditsSpentOnFuel,
      'lifetimeCreditsSpentOnGoods': lifetimeCreditsSpentOnGoods,
      'lifetimeCreditsSpentOnUpgrades': lifetimeCreditsSpentOnUpgrades,
      'lifetimeCreditsEarned': lifetimeCreditsEarned,
      'isIntroActive': isIntroActive,
      'introCharIndex': introCharIndex,
      'firstChoiceActive': firstChoiceActive,
      'isNarrativeActive': isNarrativeActive,
      'narrativeCharIndex': narrativeCharIndex,
      'narrativeSystemId': narrativeSystemId,
      'currentNarrativeText': currentNarrativeText,
      'systemFirstVisit': systemFirstVisit,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final planetsMap = <String, Planet>{};
    final planetsJson = json['planets'] as Map<String, dynamic>;
    planetsJson.forEach((k, v) {
      planetsMap[k] = Planet.fromJson(v as Map<String, dynamic>);
    });

    final upgradesMap = <String, ShipUpgrade>{};
    final upgradesJson = json['shipUpgrades'] as Map<String, dynamic>?;
    if (upgradesJson != null) {
      upgradesJson.forEach((k, v) {
        upgradesMap[k] = ShipUpgrade.fromJson(v as Map<String, dynamic>);
      });
    } else {
      // Fallback for old saves that don't have upgrades
      upgradesMap['fuel'] = ShipUpgrade.initial('fuel');
      upgradesMap['cargo'] = ShipUpgrade.initial('cargo');
    }

    // Ensure new upgrade types exist (for saves before they were added)
    if (!upgradesMap.containsKey('computer')) {
      upgradesMap['computer'] = ShipUpgrade.initial('computer');
    }
    if (!upgradesMap.containsKey('engine')) {
      upgradesMap['engine'] = ShipUpgrade.initial('engine');
    }

    final systemFirstVisitJson =
        json['systemFirstVisit'] as Map<String, dynamic>?;
    final systemFirstVisit = <String, bool>{
      for (final planetId in GameConstants.planetIds)
        planetId: systemFirstVisitJson?[planetId] as bool? ?? true,
    };

    final routeUsageJson = json['routeUsage'] as Map<String, dynamic>?;
    final routeUsage = routeUsageJson != null
        ? Map<String, int>.from(routeUsageJson)
        : <String, int>{};

    final routeRecoveryJson =
        json['routeRecoveryCounter'] as Map<String, dynamic>?;
    final routeRecoveryCounter = routeRecoveryJson != null
        ? Map<String, int>.from(routeRecoveryJson)
        : <String, int>{};

    // Handle access states: support both old and new formats
    Map<String, CRAccessState> tierAccessStates;
    final tierAccessJson =
        json['tierAccessStates'] as Map<String, dynamic>?;
    if (tierAccessJson != null) {
      // New format
      tierAccessStates = tierAccessJson.map((k, v) {
        return MapEntry(k, CRAccessState.fromJson(v as Map<String, dynamic>));
      });
    } else {
      // Legacy format: convert old tier unlock booleans to new format
      final tier1Unlocked = json['tier1Unlocked'] as bool? ?? false;
      final tier2Unlocked = json['tier2Unlocked'] as bool? ?? false;
      final tier3Unlocked = json['tier3Unlocked'] as bool? ?? false;
      final tier4Unlocked = json['tier4Unlocked'] as bool? ?? false;

      tierAccessStates = {
        '1': CRAccessState(
            discovered: tier1Unlocked,
            accessActive: false), // Access will be recalculated
        '2': CRAccessState(
            discovered: tier2Unlocked, accessActive: false),
        '3': CRAccessState(
            discovered: tier3Unlocked, accessActive: false),
        '4': CRAccessState(
            discovered: tier4Unlocked, accessActive: false),
      };
    }

    return GameState(
      location: json['location'] as String,
      fuel: json['fuel'] as int,
      credits: json['credits'] as int,
      highestCreditsReached:
          json['highestCreditsReached'] as int? ?? json['credits'] as int,
      cargo: Map<String, int>.from(json['cargo'] as Map),
      planets: planetsMap,
      log: List<String>.from(json['log'] as List),
      shipUpgrades: upgradesMap,
      shipClass: json['shipClass'] as String? ?? 'CLASS-B',
      tierAccessStates: tierAccessStates,
      routeUsage: routeUsage,
      routeRecoveryCounter: routeRecoveryCounter,
      captainName: json['captainName'] as String? ?? '',
      shipName: json['shipName'] as String? ?? '',
      currentSessionId: json['currentSessionId'] as String? ?? '',
      totalFuelUsed: json['totalFuelUsed'] as int? ?? 0,
      totalCreditsSpentOnFuel: json['totalCreditsSpentOnFuel'] as int? ?? 0,
      totalCreditsSpentOnGoods: json['totalCreditsSpentOnGoods'] as int? ?? 0,
      totalCreditsSpentOnUpgrades:
          json['totalCreditsSpentOnUpgrades'] as int? ?? 0,
      totalCreditsEarned: json['totalCreditsEarned'] as int? ?? 0,
      lifetimeFuelUsed: json['lifetimeFuelUsed'] as int? ?? 0,
      lifetimeCreditsSpentOnFuel:
          json['lifetimeCreditsSpentOnFuel'] as int? ?? 0,
      lifetimeCreditsSpentOnGoods:
          json['lifetimeCreditsSpentOnGoods'] as int? ?? 0,
      lifetimeCreditsSpentOnUpgrades:
          json['lifetimeCreditsSpentOnUpgrades'] as int? ?? 0,
      lifetimeCreditsEarned: json['lifetimeCreditsEarned'] as int? ?? 0,
      isIntroActive: json['isIntroActive'] as bool? ?? false,
      introCharIndex: json['introCharIndex'] as int? ?? 0,
      firstChoiceActive: json['firstChoiceActive'] as bool? ?? false,
      isNarrativeActive: json['isNarrativeActive'] as bool? ?? false,
      narrativeCharIndex: json['narrativeCharIndex'] as int? ?? 0,
      narrativeSystemId: json['narrativeSystemId'] as String? ?? '',
      currentNarrativeText: json['currentNarrativeText'] as String? ?? '',
      systemFirstVisit: systemFirstVisit,
    );
  }

  /// Reset session statistics while preserving lifetime statistics.
  /// Called when ending the current run/session to prepare for the next session.
  GameState resetSessionStats() {
    return GameState(
      location: location,
      fuel: fuel,
      credits: credits,
      highestCreditsReached: highestCreditsReached,
      cargo: Map<String, int>.from(cargo),
      planets: Map<String, Planet>.from(planets),
      log: [],
      shipUpgrades: Map<String, ShipUpgrade>.from(shipUpgrades),
      shipClass: shipClass,
      tierAccessStates: Map<String, CRAccessState>.from(tierAccessStates),
      routeUsage: Map<String, int>.from(routeUsage),
      routeRecoveryCounter: Map<String, int>.from(routeRecoveryCounter),
      captainName: captainName,
      shipName: shipName,
      currentSessionId: '',
      totalFuelUsed: 0,
      totalCreditsSpentOnFuel: 0,
      totalCreditsSpentOnGoods: 0,
      totalCreditsSpentOnUpgrades: 0,
      totalCreditsEarned: 0,
      lifetimeFuelUsed: lifetimeFuelUsed + totalFuelUsed,
      lifetimeCreditsSpentOnFuel:
          lifetimeCreditsSpentOnFuel + totalCreditsSpentOnFuel,
      lifetimeCreditsSpentOnGoods:
          lifetimeCreditsSpentOnGoods + totalCreditsSpentOnGoods,
      lifetimeCreditsSpentOnUpgrades:
          lifetimeCreditsSpentOnUpgrades + totalCreditsSpentOnUpgrades,
      lifetimeCreditsEarned: lifetimeCreditsEarned + totalCreditsEarned,
      isIntroActive: false,
      introCharIndex: 0,
      firstChoiceActive: false,
      isNarrativeActive: false,
      narrativeCharIndex: 0,
      narrativeSystemId: '',
      systemFirstVisit: Map<String, bool>.from(systemFirstVisit),
    );
  }
}
