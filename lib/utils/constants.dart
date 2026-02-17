import '../models/ship_upgrade.dart';

class GameConstants {
  static const int initialFuel = 10;
  static const int initialCredits = 1000;
  static const int finalCreditMilestone = 25000;
  static const List<int> creditLevelMilestones = [
    1000,
    2500,
    5000,
    10000,
    15000,
    20000,
    finalCreditMilestone,
  ];
  static const String initialLocation = 'HELIOS REACH';

  static const List<String> planetIds = ['HELIOS REACH', 'KESTREL BELT', 'SOLACE STATION', 'MERIDIAN OUTPOST'];
  static const List<String> itemIds = ['Food', 'Ore', 'Medicine'];

  // Travel costs (fuel required)
  static const Map<String, Map<String, int>> travelCosts = {
    'HELIOS REACH': {'HELIOS REACH': 0, 'KESTREL BELT': 3, 'SOLACE STATION': 4, 'MERIDIAN OUTPOST': 5},
    'KESTREL BELT': {'HELIOS REACH': 3, 'KESTREL BELT': 0, 'SOLACE STATION': 3, 'MERIDIAN OUTPOST': 4},
    'SOLACE STATION': {'HELIOS REACH': 4, 'KESTREL BELT': 3, 'SOLACE STATION': 0, 'MERIDIAN OUTPOST': 3},
    'MERIDIAN OUTPOST': {'HELIOS REACH': 5, 'KESTREL BELT': 4, 'SOLACE STATION': 3, 'MERIDIAN OUTPOST': 0},
  };

  // Base ask prices (what you pay to buy)
  static const Map<String, Map<String, int>> baseAskPrices = {
    'HELIOS REACH': {'Food': 50, 'Ore': 80, 'Medicine': 120},
    'KESTREL BELT': {'Food': 30, 'Ore': 100, 'Medicine': 150},
    'SOLACE STATION': {'Food': 70, 'Ore': 40, 'Medicine': 140},
    'MERIDIAN OUTPOST': {'Food': 60, 'Ore': 90, 'Medicine': 80},
  };

  // Fuel prices per planet
  static const Map<String, int> fuelPrices = {
    'HELIOS REACH': 10,
    'KESTREL BELT': 8,
    'SOLACE STATION': 12,
    'MERIDIAN OUTPOST': 15,
  };

  // Planet descriptions
  static const Map<String, String> planetDescriptions = {
    'HELIOS REACH':
        'The central trading hub and your starting point. Prices are moderate and stable across all goods. An ideal market for cautious traders to learn the ropes.',
    'KESTREL BELT':
        'A volatile asteroid belt rich in ore deposits. Ore prices fluctuate wildly based on mining operations. Risk-takers can profit from the unstable market.',
    'SOLACE STATION':
        'A stable mining colony with predictable, consistent pricing. Reliable market conditions make this a steady choice for dependable traders.',
    'MERIDIAN OUTPOST':
        'A rare medical research outpost with scarce goods and premium prices. High-risk, high-reward trading opportunities await those seeking fortune.',
  };

  // Ship upgrade tiers: indexed by tier (0=Base, 1=Tier 1, 2=Tier 2)
  // Each tier has the same capacity for both fuel and cargo
  static const List<ShipUpgradeTier> upgradeTiers = [
    ShipUpgradeTier(
      name: 'Base',
      capacity: 10,
      cost: 0,
    ),
    ShipUpgradeTier(
      name: 'Tier 1',
      capacity: 15,
      cost: 0, // Will be set per upgrade type below
    ),
    ShipUpgradeTier(
      name: 'Tier 2',
      capacity: 20,
      cost: 0, // Will be set per upgrade type below
    ),
  ];

  // Upgrade costs per type and tier
  static const Map<String, Map<int, int>> upgradeCosts = {
    'fuel': {
      0: 0, // Base
      1: 100, // Tier 1
      2: 250, // Tier 2
    },
    'cargo': {
      0: 0, // Base
      1: 200, // Tier 1
      2: 500, // Tier 2
    },
  };

  static int getUpgradeCost(String upgradeType, int tier) {
    return upgradeCosts[upgradeType]?[tier] ?? 0;
  }

  static int getUpgradeCapacity(int tier) {
    if (tier < 0 || tier >= upgradeTiers.length) return 10;
    return upgradeTiers[tier].capacity;
  }

  static int getUnlockedLevelForHighestCredits(int highestCreditsReached) {
    var level = 0;
    for (final milestone in creditLevelMilestones) {
      if (highestCreditsReached >= milestone) {
        level++;
      }
    }
    return level;
  }
}
