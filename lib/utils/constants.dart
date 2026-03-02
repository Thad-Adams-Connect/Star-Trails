// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import '../models/ship_upgrade.dart';
import '../models/cr_access_state.dart';

class MarketItemPrice {
  final int buy;
  final int sell;

  const MarketItemPrice({required this.buy, required this.sell});
}

class GameConstants {
  static const int initialFuel = 10;
  static const int initialCredits = 1000;
  static const int finalCreditMilestone = 25000;
  static const List<int> creditLevelMilestones = [
    5000,   // Tier 1 unlock threshold
    10000,  // Tier 2 unlock threshold
    18000,  // Tier 3 unlock threshold
    25000,  // Tier 4 unlock threshold (final milestone)
  ];

  // Credit progression unlock thresholds
  static const int unlockTier1Credits = 5000; // S5-S6, Tech, Computer
  static const int unlockTier2Credits = 10000; // S7-S8, Luxury, Engine
  static const int unlockTier3Credits = 18000; // S9-S10, Class-C Ship
  static const int unlockTier4Credits = 25000; // S11-S12

  // Route exploit control constants
  static const int routeFreeUses =
      3; // Number of uses before price adjustments begin
  static const int routeUsesPerAdjustment =
      2; // Uses needed for each 5% price change
  static const double routePriceAdjustmentPercent =
      0.05; // 5% price change per adjustment
  static const int routeRecoveryThreshold =
      5; // Different trades needed for recovery
  static const int routeRecoveryAmount = 2; // Uses removed on recovery
  static const int minFuelPerTrip = 3; // Minimum fuel cost for any trip

  static const String initialLocation = 'HELIOS REACH';

  // Inner Ring systems (always available)
  static const List<String> innerRingPlanetIds = [
    'HELIOS REACH',
    'KESTREL BELT',
    'SOLACE STATION',
    'MERIDIAN OUTPOST'
  ];

  // Tier 1 systems (unlock at 5000cr)
  static const List<String> tier1PlanetIds = [
    'ORIVAULT COMPLEX',
    'CANDESCENT YARD'
  ];

  // Tier 2 systems (unlock at 10000cr)
  static const List<String> tier2PlanetIds = [
    'FLUXHAVEN INSTITUTE',
    'VELARIS ENCLAVE'
  ];

  // Tier 3 systems (unlock at 18000cr)
  static const List<String> tier3PlanetIds = [
    'GATEFORGE BASTION',
    'REDHAVEN ANCHORPOINT'
  ];

  // Tier 4 systems (unlock at 25000cr)
  static const List<String> tier4PlanetIds = [
    'STARTRAIL EXPANSE',
    'OUTERCREST NEXUS'
  ];

  // All systems combined (for backward compatibility)
  static const List<String> planetIds = [
    ...innerRingPlanetIds,
    ...tier1PlanetIds,
    ...tier2PlanetIds,
    ...tier3PlanetIds,
    ...tier4PlanetIds,
  ];

  // Base commodities (always available)
  static const List<String> baseCommodityIds = ['Food', 'Ore', 'Medicine'];

  // Tier 1 commodities (unlock at 5000cr)
  static const List<String> tier1CommodityIds = ['Tech'];

  // Tier 2 commodities (unlock at 10000cr)
  static const List<String> tier2CommodityIds = ['Luxury'];

  // All commodities combined
  static const List<String> itemIds = [
    ...baseCommodityIds,
    ...tier1CommodityIds,
    ...tier2CommodityIds,
  ];

  // Travel costs (fuel required)
  // Minimum 3 fuel per trip, never below this floor
  static const Map<String, Map<String, int>> travelCosts = {
    // Inner Ring systems
    'HELIOS REACH': {
      'HELIOS REACH': 0,
      'KESTREL BELT': 3,
      'SOLACE STATION': 4,
      'MERIDIAN OUTPOST': 5,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 5,
      'VELARIS ENCLAVE': 5,
      'GATEFORGE BASTION': 6,
      'REDHAVEN ANCHORPOINT': 6,
      'STARTRAIL EXPANSE': 8,
      'OUTERCREST NEXUS': 8,
    },
    'KESTREL BELT': {
      'HELIOS REACH': 3,
      'KESTREL BELT': 0,
      'SOLACE STATION': 3,
      'MERIDIAN OUTPOST': 4,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 5,
      'VELARIS ENCLAVE': 5,
      'GATEFORGE BASTION': 6,
      'REDHAVEN ANCHORPOINT': 6,
      'STARTRAIL EXPANSE': 8,
      'OUTERCREST NEXUS': 8,
    },
    'SOLACE STATION': {
      'HELIOS REACH': 4,
      'KESTREL BELT': 3,
      'SOLACE STATION': 0,
      'MERIDIAN OUTPOST': 3,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 5,
      'VELARIS ENCLAVE': 5,
      'GATEFORGE BASTION': 6,
      'REDHAVEN ANCHORPOINT': 6,
      'STARTRAIL EXPANSE': 8,
      'OUTERCREST NEXUS': 8,
    },
    'MERIDIAN OUTPOST': {
      'HELIOS REACH': 5,
      'KESTREL BELT': 4,
      'SOLACE STATION': 3,
      'MERIDIAN OUTPOST': 0,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 5,
      'VELARIS ENCLAVE': 5,
      'GATEFORGE BASTION': 6,
      'REDHAVEN ANCHORPOINT': 6,
      'STARTRAIL EXPANSE': 8,
      'OUTERCREST NEXUS': 8,
    },
    // Tier 1 systems (5000cr unlock)
    'ORIVAULT COMPLEX': {
      'HELIOS REACH': 4,
      'KESTREL BELT': 4,
      'SOLACE STATION': 4,
      'MERIDIAN OUTPOST': 4,
      'ORIVAULT COMPLEX': 0,
      'CANDESCENT YARD': 3,
      'FLUXHAVEN INSTITUTE': 4,
      'VELARIS ENCLAVE': 4,
      'GATEFORGE BASTION': 5,
      'REDHAVEN ANCHORPOINT': 5,
      'STARTRAIL EXPANSE': 7,
      'OUTERCREST NEXUS': 7,
    },
    'CANDESCENT YARD': {
      'HELIOS REACH': 4,
      'KESTREL BELT': 4,
      'SOLACE STATION': 4,
      'MERIDIAN OUTPOST': 4,
      'ORIVAULT COMPLEX': 3,
      'CANDESCENT YARD': 0,
      'FLUXHAVEN INSTITUTE': 4,
      'VELARIS ENCLAVE': 4,
      'GATEFORGE BASTION': 5,
      'REDHAVEN ANCHORPOINT': 5,
      'STARTRAIL EXPANSE': 7,
      'OUTERCREST NEXUS': 7,
    },
    // Tier 2 systems (10000cr unlock)
    'FLUXHAVEN INSTITUTE': {
      'HELIOS REACH': 5,
      'KESTREL BELT': 5,
      'SOLACE STATION': 5,
      'MERIDIAN OUTPOST': 5,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 0,
      'VELARIS ENCLAVE': 3,
      'GATEFORGE BASTION': 4,
      'REDHAVEN ANCHORPOINT': 4,
      'STARTRAIL EXPANSE': 6,
      'OUTERCREST NEXUS': 6,
    },
    'VELARIS ENCLAVE': {
      'HELIOS REACH': 5,
      'KESTREL BELT': 5,
      'SOLACE STATION': 5,
      'MERIDIAN OUTPOST': 5,
      'ORIVAULT COMPLEX': 4,
      'CANDESCENT YARD': 4,
      'FLUXHAVEN INSTITUTE': 3,
      'VELARIS ENCLAVE': 0,
      'GATEFORGE BASTION': 4,
      'REDHAVEN ANCHORPOINT': 4,
      'STARTRAIL EXPANSE': 6,
      'OUTERCREST NEXUS': 6,
    },
    // Tier 3 systems (18000cr unlock)
    'GATEFORGE BASTION': {
      'HELIOS REACH': 6,
      'KESTREL BELT': 6,
      'SOLACE STATION': 6,
      'MERIDIAN OUTPOST': 6,
      'ORIVAULT COMPLEX': 5,
      'CANDESCENT YARD': 5,
      'FLUXHAVEN INSTITUTE': 4,
      'VELARIS ENCLAVE': 4,
      'GATEFORGE BASTION': 0,
      'REDHAVEN ANCHORPOINT': 3,
      'STARTRAIL EXPANSE': 5,
      'OUTERCREST NEXUS': 5,
    },
    'REDHAVEN ANCHORPOINT': {
      'HELIOS REACH': 6,
      'KESTREL BELT': 6,
      'SOLACE STATION': 6,
      'MERIDIAN OUTPOST': 6,
      'ORIVAULT COMPLEX': 5,
      'CANDESCENT YARD': 5,
      'FLUXHAVEN INSTITUTE': 4,
      'VELARIS ENCLAVE': 4,
      'GATEFORGE BASTION': 3,
      'REDHAVEN ANCHORPOINT': 0,
      'STARTRAIL EXPANSE': 5,
      'OUTERCREST NEXUS': 5,
    },
    // Tier 4 systems (25000cr unlock)
    'STARTRAIL EXPANSE': {
      'HELIOS REACH': 8,
      'KESTREL BELT': 8,
      'SOLACE STATION': 8,
      'MERIDIAN OUTPOST': 8,
      'ORIVAULT COMPLEX': 7,
      'CANDESCENT YARD': 7,
      'FLUXHAVEN INSTITUTE': 6,
      'VELARIS ENCLAVE': 6,
      'GATEFORGE BASTION': 5,
      'REDHAVEN ANCHORPOINT': 5,
      'STARTRAIL EXPANSE': 0,
      'OUTERCREST NEXUS': 3,
    },
    'OUTERCREST NEXUS': {
      'HELIOS REACH': 8,
      'KESTREL BELT': 8,
      'SOLACE STATION': 8,
      'MERIDIAN OUTPOST': 8,
      'ORIVAULT COMPLEX': 7,
      'CANDESCENT YARD': 7,
      'FLUXHAVEN INSTITUTE': 6,
      'VELARIS ENCLAVE': 6,
      'GATEFORGE BASTION': 5,
      'REDHAVEN ANCHORPOINT': 5,
      'STARTRAIL EXPANSE': 3,
      'OUTERCREST NEXUS': 0,
    },
  };

  // Base market prices (BUY = player pays, SELL = player receives)
  static const Map<String, Map<String, MarketItemPrice>> marketPrices = {
    // Inner Ring systems
    'HELIOS REACH': {
      'Food': MarketItemPrice(buy: 55, sell: 52),
      'Ore': MarketItemPrice(buy: 65, sell: 62),
      'Medicine': MarketItemPrice(buy: 85, sell: 82),
      'Tech': MarketItemPrice(buy: 120, sell: 115),
      'Luxury': MarketItemPrice(buy: 180, sell: 172),
    },
    'SOLACE STATION': {
      'Food': MarketItemPrice(buy: 58, sell: 54),
      'Ore': MarketItemPrice(buy: 45, sell: 42),
      'Medicine': MarketItemPrice(buy: 92, sell: 88),
      'Tech': MarketItemPrice(buy: 125, sell: 118),
      'Luxury': MarketItemPrice(buy: 195, sell: 185),
    },
    'KESTREL BELT': {
      'Food': MarketItemPrice(buy: 65, sell: 53),
      'Ore': MarketItemPrice(buy: 30, sell: 28),
      'Medicine': MarketItemPrice(buy: 105, sell: 98),
      'Tech': MarketItemPrice(buy: 110, sell: 105),
      'Luxury': MarketItemPrice(buy: 210, sell: 195),
    },
    'MERIDIAN OUTPOST': {
      'Food': MarketItemPrice(buy: 28, sell: 26),
      'Ore': MarketItemPrice(buy: 65, sell: 55),
      'Medicine': MarketItemPrice(buy: 75, sell: 72),
      'Tech': MarketItemPrice(buy: 140, sell: 130),
      'Luxury': MarketItemPrice(buy: 165, sell: 158),
    },
    // Tier 1 systems (5000cr unlock)
    'ORIVAULT COMPLEX': {
      'Food': MarketItemPrice(buy: 62, sell: 58),
      'Ore': MarketItemPrice(buy: 58, sell: 54),
      'Medicine': MarketItemPrice(buy: 88, sell: 84),
      'Tech': MarketItemPrice(buy: 95, sell: 92),
      'Luxury': MarketItemPrice(buy: 200, sell: 190),
    },
    'CANDESCENT YARD': {
      'Food': MarketItemPrice(buy: 60, sell: 55),
      'Ore': MarketItemPrice(buy: 55, sell: 50),
      'Medicine': MarketItemPrice(buy: 98, sell: 92),
      'Tech': MarketItemPrice(buy: 115, sell: 110),
      'Luxury': MarketItemPrice(buy: 188, sell: 180),
    },
    // Tier 2 systems (10000cr unlock)
    'FLUXHAVEN INSTITUTE': {
      'Food': MarketItemPrice(buy: 68, sell: 62),
      'Ore': MarketItemPrice(buy: 62, sell: 58),
      'Medicine': MarketItemPrice(buy: 95, sell: 90),
      'Tech': MarketItemPrice(buy: 108, sell: 104),
      'Luxury': MarketItemPrice(buy: 175, sell: 168),
    },
    'VELARIS ENCLAVE': {
      'Food': MarketItemPrice(buy: 70, sell: 64),
      'Ore': MarketItemPrice(buy: 72, sell: 66),
      'Medicine': MarketItemPrice(buy: 102, sell: 96),
      'Tech': MarketItemPrice(buy: 130, sell: 122),
      'Luxury': MarketItemPrice(buy: 155, sell: 150),
    },
    // Tier 3 systems (18000cr unlock)
    'GATEFORGE BASTION': {
      'Food': MarketItemPrice(buy: 72, sell: 66),
      'Ore': MarketItemPrice(buy: 48, sell: 45),
      'Medicine': MarketItemPrice(buy: 110, sell: 102),
      'Tech': MarketItemPrice(buy: 125, sell: 118),
      'Luxury': MarketItemPrice(buy: 205, sell: 195),
    },
    'REDHAVEN ANCHORPOINT': {
      'Food': MarketItemPrice(buy: 48, sell: 45),
      'Ore': MarketItemPrice(buy: 75, sell: 68),
      'Medicine': MarketItemPrice(buy: 88, sell: 82),
      'Tech': MarketItemPrice(buy: 145, sell: 135),
      'Luxury': MarketItemPrice(buy: 192, sell: 182),
    },
    // Tier 4 systems (25000cr unlock)
    'STARTRAIL EXPANSE': {
      'Food': MarketItemPrice(buy: 42, sell: 38),
      'Ore': MarketItemPrice(buy: 82, sell: 75),
      'Medicine': MarketItemPrice(buy: 118, sell: 108),
      'Tech': MarketItemPrice(buy: 152, sell: 140),
      'Luxury': MarketItemPrice(buy: 220, sell: 205),
    },
    'OUTERCREST NEXUS': {
      'Food': MarketItemPrice(buy: 78, sell: 70),
      'Ore': MarketItemPrice(buy: 68, sell: 62),
      'Medicine': MarketItemPrice(buy: 125, sell: 115),
      'Tech': MarketItemPrice(buy: 138, sell: 128),
      'Luxury': MarketItemPrice(buy: 185, sell: 175),
    },
  };

  static MarketItemPrice getMarketPrice(String systemId, String itemId) {
    return marketPrices[systemId]![itemId]!;
  }

  // Fuel prices per planet
  static const Map<String, int> fuelPrices = {
    'HELIOS REACH': 10,
    'KESTREL BELT': 8,
    'SOLACE STATION': 12,
    'MERIDIAN OUTPOST': 15,
    'ORIVAULT COMPLEX': 11,
    'CANDESCENT YARD': 9,
    'FLUXHAVEN INSTITUTE': 10,
    'VELARIS ENCLAVE': 13,
    'GATEFORGE BASTION': 12,
    'REDHAVEN ANCHORPOINT': 14,
    'STARTRAIL EXPANSE': 16,
    'OUTERCREST NEXUS': 15,
  };

  // Planet descriptions
  static const Map<String, String> planetDescriptions = {
    'HELIOS REACH':
        'The stable Inner Ring hub and your starting point. Tight spreads and low volatility make it a safe place to stabilize and upgrade your ship.',
    'KESTREL BELT':
        'An industrial asteroid belt with abundant ore. Ore is cheap to buy here, while medicine sells at a premium.',
    'SOLACE STATION':
        'A structured training hub with steady storage and moderate margins. A reliable environment for learning trade routes.',
    'MERIDIAN OUTPOST':
        'An agricultural frontier system. Food is cheapest here, and ore demand runs high for outbound trade.',
    'ORIVAULT COMPLEX':
        'A research and fabrication colony specializing in navigation and computer systems. Located beyond the Inner Ring, it offers technology at competitive prices.',
    'CANDESCENT YARD':
        'Large-scale energy testing platforms with experimental propulsion systems. Fuel efficiency trials occur here daily.',
    'FLUXHAVEN INSTITUTE':
        'A propulsion research center focused on reducing fuel waste. Advanced engine technology development happens here.',
    'VELARIS ENCLAVE':
        'Design studios producing luxury navigation systems and refined interior modules. Demand for luxury goods fluctuates rapidly.',
    'GATEFORGE BASTION':
        'Dry docks specializing in vessel reinforcement and expanded cargo structures for long-range operations.',
    'REDHAVEN ANCHORPOINT':
        'A docking array along unpredictable jump corridors. Supply varies with clustered arrivals. Gateway to deeper expansion.',
    'STARTRAIL EXPANSE':
        'Exploratory settlement beyond established hubs. Minimal infrastructure means supply cycles are smaller and prices shift rapidly.',
    'OUTERCREST NEXUS':
        'The farthest established junction before uncharted corridors. Lean infrastructure means large shipments significantly influence prices.',
  };

  // Ship upgrade progression: indexed by level (0=Base, 1=Enhanced, 2=Advanced)
  // Each level has the same capacity for both fuel and cargo
  static const List<ShipUpgradeTier> upgradeTiers = [
    ShipUpgradeTier(
      name: 'Base',
      capacity: 10,
      cost: 0,
    ),
    ShipUpgradeTier(
      name: 'Enhanced',
      capacity: 15,
      cost: 0, // Will be set per upgrade type below
    ),
    ShipUpgradeTier(
      name: 'Advanced',
      capacity: 20,
      cost: 0, // Will be set per upgrade type below
    ),
  ];

  // Upgrade costs per type and progression level
  static const Map<String, Map<int, int>> upgradeCosts = {
    'fuel': {
      0: 0, // Base
      1: 100, // Enhanced
      2: 250, // Advanced
    },
    'cargo': {
      0: 0, // Base
      1: 200, // Enhanced
      2: 500, // Advanced
    },
    'computer': {
      0: 0, // None
      1: 300, // Enhanced - TRIP command
      2: 600, // Advanced - MARKET command
    },
    'engine': {
      0: 0, // None
      1: 500, // Enhanced - 1 fuel reduction
      2: 1000, // Advanced - 2 fuel reduction total
    },
  };

  // Ship specifications
  static const Map<String, ShipSpec> shipSpecs = {
    'CLASS-B': ShipSpec(
      name: 'CLASS-B',
      fuelCapacity: 10,
      cargoCapacity: 10,
      baseCost: 0, // Starting ship
      resaleValue: 0,
      description: 'Your starting ship. Modest capacity but reliable.',
    ),
    'CLASS-C': ShipSpec(
      name: 'CLASS-C',
      fuelCapacity: 30,
      cargoCapacity: 40,
      baseCost: 14000,
      resaleValue: 7500,
      description:
          'Advanced trader vessel with enhanced capacity and integrated Computer systems (T1+T2).',
      includesComputerT1: true,
      includesComputerT2: true,
    ),
  };

  // Computer upgrade descriptions
  static const Map<int, String> computerUpgradeDescriptions = {
    0: 'No computer system installed',
    1: 'TRIP command - Display fuel required to any destination',
    2: 'MARKET command - View market prices at any system remotely',
  };

  // Engine upgrade descriptions
  static const Map<int, String> engineUpgradeDescriptions = {
    0: 'Standard engine efficiency',
    1: 'Reduces all fuel costs by 1 (minimum 3 fuel)',
    2: 'Reduces all fuel costs by 2 (minimum 3 fuel)',
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

  // System access helpers - based on accessActive state (with hysteresis)
  static bool isTier1SystemActive(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['1']?.accessActive ?? false;
  static bool isTier2SystemActive(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['2']?.accessActive ?? false;
  static bool isTier3SystemActive(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['3']?.accessActive ?? false;
  static bool isTier4SystemActive(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['4']?.accessActive ?? false;

  // Commodity/Upgrade helpers - based on discovered state (permanent once unlocked)
  static bool isTier1Discovered(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['1']?.discovered ?? false;
  static bool isTier2Discovered(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['2']?.discovered ?? false;
  static bool isTier3Discovered(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['3']?.discovered ?? false;
  static bool isTier4Discovered(Map<String, CRAccessState> tierAccessStates) =>
      tierAccessStates['4']?.discovered ?? false;

  static bool isSystemUnlocked(String systemId, Map<String, CRAccessState> tierAccessStates) {
    if (innerRingPlanetIds.contains(systemId)) {
      return true;
    }
    if (tier1PlanetIds.contains(systemId)) {
      return isTier1SystemActive(tierAccessStates);
    }
    if (tier2PlanetIds.contains(systemId)) {
      return isTier2SystemActive(tierAccessStates);
    }
    if (tier3PlanetIds.contains(systemId)) {
      return isTier3SystemActive(tierAccessStates);
    }
    if (tier4PlanetIds.contains(systemId)) {
      return isTier4SystemActive(tierAccessStates);
    }
    return false;
  }

  static bool isCommodityUnlocked(String commodityId, Map<String, CRAccessState> tierAccessStates) {
    if (baseCommodityIds.contains(commodityId)) {
      return true;
    }
    if (tier1CommodityIds.contains(commodityId)) {
      return isTier1Discovered(tierAccessStates);
    }
    if (tier2CommodityIds.contains(commodityId)) {
      return isTier2Discovered(tierAccessStates);
    }
    return false;
  }

  static bool isComputerUpgradeUnlocked(Map<String, CRAccessState> tierAccessStates) =>
      isTier1Discovered(tierAccessStates);
  static bool isEngineUpgradeUnlocked(Map<String, CRAccessState> tierAccessStates) =>
      isTier2Discovered(tierAccessStates);
  static bool isClassCShipUnlocked(Map<String, CRAccessState> tierAccessStates) =>
      isTier3Discovered(tierAccessStates);

  static List<String> getAvailableSystems(Map<String, CRAccessState> tierAccessStates) {
    return planetIds
        .where((id) => isSystemUnlocked(id, tierAccessStates))
        .toList();
  }

  static List<String> getAvailableCommodities(Map<String, CRAccessState> tierAccessStates) {
    return itemIds
        .where((id) => isCommodityUnlocked(id, tierAccessStates))
        .toList();
  }

  // Calculate actual fuel cost with engine upgrades applied
  // Returns at least minFuelPerTrip (minimum floor)
  static int calculateFuelCost(String from, String to, int engineTier) {
    final baseCost = travelCosts[from]?[to] ?? 999;
    final reduction = engineTier; // Tier 1 = -1, Tier 2 = -2
    final adjustedCost = baseCost - reduction;
    return adjustedCost < minFuelPerTrip ? minFuelPerTrip : adjustedCost;
  }
}
