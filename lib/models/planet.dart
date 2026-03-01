// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import '../utils/constants.dart';

class Planet {
  final String id;
  final Map<String, int> demandIndex; // 0-3 for each item

  Planet({required this.id, Map<String, int>? demandIndex})
      : demandIndex = demandIndex ?? _initDemand();

  static Map<String, int> _initDemand() {
    return {for (var item in GameConstants.itemIds) item: 3};
  }

  int getAskPrice(String itemId) {
    return GameConstants.getMarketPrice(id, itemId).buy;
  }

  int getBidPrice(String itemId) {
    final marketPrice = GameConstants.getMarketPrice(id, itemId);
    final baseSell = marketPrice.sell;
    final demand = demandIndex[itemId]!;
    final double multiplier;
    if (demand == 0) {
      multiplier = 0.9;
    } else if (demand == 1) {
      multiplier = 0.95;
    } else {
      multiplier = 1.0;
    }

    var adjustedBid = (baseSell * multiplier).floor();

    // Ensure bid < ask by at least 1
    if (adjustedBid >= marketPrice.buy) {
      adjustedBid = marketPrice.buy - 1;
    }

    return adjustedBid;
  }

  int getFuelPrice() {
    return GameConstants.fuelPrices[id]!;
  }

  String getDescription() {
    return GameConstants.planetDescriptions[id]!;
  }

  Planet decreaseDemand(String itemId) {
    final newDemand = Map<String, int>.from(demandIndex);
    newDemand[itemId] = (newDemand[itemId]! - 1).clamp(0, 3);
    return Planet(id: id, demandIndex: newDemand);
  }

  Planet increaseDemandAll() {
    final newDemand = Map<String, int>.from(demandIndex);
    for (var item in GameConstants.itemIds) {
      newDemand[item] = (newDemand[item]! + 1).clamp(0, 3);
    }
    return Planet(id: id, demandIndex: newDemand);
  }

  Map<String, dynamic> toJson() => {'id': id, 'demandIndex': demandIndex};

  factory Planet.fromJson(Map<String, dynamic> json) {
    final demandIndexJson = Map<String, int>.from(json['demandIndex'] as Map);

    // Ensure all current itemIds have entries (for backward compatibility)
    for (var item in GameConstants.itemIds) {
      if (!demandIndexJson.containsKey(item)) {
        demandIndexJson[item] = 3; // Default demand level
      }
    }

    return Planet(
      id: json['id'] as String,
      demandIndex: demandIndexJson,
    );
  }
}
