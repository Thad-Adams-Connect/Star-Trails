/// Represents a ship upgrade tier with its capacity and cost.
class ShipUpgradeTier {
  final String name; // "Base", "Tier 1", "Tier 2"
  final int capacity;
  final int cost;

  const ShipUpgradeTier({
    required this.name,
    required this.capacity,
    required this.cost,
  });

  factory ShipUpgradeTier.fromJson(Map<String, dynamic> json) {
    return ShipUpgradeTier(
      name: json['name'] as String,
      capacity: json['capacity'] as int,
      cost: json['cost'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'capacity': capacity,
      'cost': cost,
    };
  }
}

/// Represents the current state of a specific upgrade type (fuel or cargo).
class ShipUpgrade {
  final String type; // "fuel" or "cargo"
  final int currentTier; // 0 = Base, 1 = Tier 1, 2 = Tier 2

  const ShipUpgrade({
    required this.type,
    required this.currentTier,
  });

  factory ShipUpgrade.initial(String type) {
    return ShipUpgrade(
      type: type,
      currentTier: 0, // Start at Base tier
    );
  }

  factory ShipUpgrade.fromJson(Map<String, dynamic> json) {
    return ShipUpgrade(
      type: json['type'] as String,
      currentTier: json['currentTier'] as int,
    );
  }

  ShipUpgrade upgradeTo(int tier) {
    return ShipUpgrade(
      type: type,
      currentTier: tier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'currentTier': currentTier,
    };
  }
}
