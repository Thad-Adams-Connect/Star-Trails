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

/// Represents a ship specification (different ship classes).
class ShipSpec {
  final String name;
  final int fuelCapacity;
  final int cargoCapacity;
  final int baseCost;
  final int resaleValue;
  final String description;
  final bool includesComputerT1;
  final bool includesComputerT2;

  const ShipSpec({
    required this.name,
    required this.fuelCapacity,
    required this.cargoCapacity,
    required this.baseCost,
    required this.resaleValue,
    required this.description,
    this.includesComputerT1 = false,
    this.includesComputerT2 = false,
  });

  factory ShipSpec.fromJson(Map<String, dynamic> json) {
    return ShipSpec(
      name: json['name'] as String,
      fuelCapacity: json['fuelCapacity'] as int,
      cargoCapacity: json['cargoCapacity'] as int,
      baseCost: json['baseCost'] as int,
      resaleValue: json['resaleValue'] as int,
      description: json['description'] as String,
      includesComputerT1: json['includesComputerT1'] as bool? ?? false,
      includesComputerT2: json['includesComputerT2'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fuelCapacity': fuelCapacity,
      'cargoCapacity': cargoCapacity,
      'baseCost': baseCost,
      'resaleValue': resaleValue,
      'description': description,
      'includesComputerT1': includesComputerT1,
      'includesComputerT2': includesComputerT2,
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
