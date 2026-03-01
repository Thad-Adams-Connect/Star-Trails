// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

/// Represents the state of a CR tier with discovery and dynamic access control.
/// 
/// The tier system distinguishes between DISCOVERY and ACCESS:
/// - DISCOVERY (discovered flag): Permanent. Once a tier is discovered, commodities from that 
///   tier remain tradeable forever, even if tier access is lost.
/// - ACCESS (accessActive flag): Dynamic. Systems from a tier are only accessible when tier 
///   access is active. Systems become inaccessible when credits drop below the tier threshold.
class TierState {
  /// Whether this tier has been discovered (reached for the first time).
  /// This flag is permanent and persists between sessions.
  /// Used to determine if commodities from this tier can be traded (commodities stay available once discovered).
  final bool discovered;

  /// Whether access to this tier is currently active.
  /// This is dynamically calculated based on current credits and hysteresis logic.
  /// Not directly persisted - recalculated from credits on load.
  /// Used to determine if systems from this tier are accessible (systems become inaccessible when tier access is lost).
  final bool accessActive;

  /// Whether access was previously active but got deactivated.
  /// Used for hysteresis logic (reactivation threshold differs from first activation).
  /// Persisted between sessions.
  final bool wasDeactivated;

  const TierState({
    this.discovered = false,
    this.accessActive = false,
    this.wasDeactivated = false,
  });

  TierState copyWith({
    bool? discovered,
    bool? accessActive,
    bool? wasDeactivated,
  }) {
    return TierState(
      discovered: discovered ?? this.discovered,
      accessActive: accessActive ?? this.accessActive,
      wasDeactivated: wasDeactivated ?? this.wasDeactivated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discovered': discovered,
      'wasDeactivated': wasDeactivated,
      // accessActive is not persisted - it's recalculated
    };
  }

  factory TierState.fromJson(Map<String, dynamic> json) {
    return TierState(
      discovered: json['discovered'] as bool? ?? false,
      wasDeactivated: json['wasDeactivated'] as bool? ?? false,
      // accessActive will be recalculated based on current credits
    );
  }

  @override
  String toString() {
    return 'TierState(discovered: $discovered, accessActive: $accessActive, wasDeactivated: $wasDeactivated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TierState &&
        other.discovered == discovered &&
        other.accessActive == accessActive &&
        other.wasDeactivated == wasDeactivated;
  }

  @override
  int get hashCode =>
      discovered.hashCode ^ accessActive.hashCode ^ wasDeactivated.hashCode;
}
