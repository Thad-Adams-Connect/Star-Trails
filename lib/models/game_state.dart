import 'planet.dart';
import 'ship_upgrade.dart';
import '../utils/constants.dart';

class GameState {
  final String location;
  final int fuel;
  final int credits;
  final int highestCreditsReached;
  final Map<String, int> cargo;
  final Map<String, Planet> planets;
  final List<String> log;

  // Ship upgrades: Map<type, ShipUpgrade> where type is "fuel" or "cargo"
  final Map<String, ShipUpgrade> shipUpgrades;

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
  }) : highestCreditsReached = highestCreditsReached ?? credits;

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
    };

    return GameState(
      location: GameConstants.initialLocation,
      fuel: GameConstants.initialFuel,
      credits: GameConstants.initialCredits,
      cargo: cargo,
      planets: planets,
      log: [],
      shipUpgrades: shipUpgrades,
      captainName: '',
      shipName: '',
      currentSessionId: '',
      isIntroActive: true,
      introCharIndex: 0,
      firstChoiceActive: false,
    );
  }

  int get cargoUsed {
    return cargo.values.fold(0, (sum, qty) => sum + qty);
  }

  int get cargoAvailable {
    return getCargoCapacity() - cargoUsed;
  }

  /// Get the current fuel capacity based on upgrades.
  int getFuelCapacity() {
    final fuelUpgrade = shipUpgrades['fuel']!;
    return GameConstants.upgradeTiers[fuelUpgrade.currentTier].capacity;
  }

  /// Get the current cargo capacity based on upgrades.
  int getCargoCapacity() {
    final cargoUpgrade = shipUpgrades['cargo']!;
    return GameConstants.upgradeTiers[cargoUpgrade.currentTier].capacity;
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
    );
  }
}
