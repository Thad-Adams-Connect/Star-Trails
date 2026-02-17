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
    return GameConstants.baseAskPrices[id]![itemId]!;
  }

  int getBidPrice(String itemId) {
    final baseAsk = getAskPrice(itemId);
    final baseBid = (baseAsk * 0.9).floor();
    final demand = demandIndex[itemId]!;

    int adjustedBid;
    if (demand == 0) {
      adjustedBid = (baseBid * 0.9).floor();
    } else if (demand == 1) {
      adjustedBid = (baseBid * 0.95).floor();
    } else if (demand == 2) {
      adjustedBid = baseBid;
    } else {
      adjustedBid = (baseBid * 1.05).floor();
    }

    // Ensure bid < ask by at least 1
    if (adjustedBid >= baseAsk) {
      adjustedBid = baseAsk - 1;
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
    return Planet(
      id: json['id'] as String,
      demandIndex: Map<String, int>.from(json['demandIndex'] as Map),
    );
  }
}
