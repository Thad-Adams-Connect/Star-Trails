// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

/// Represents the state of a CR access level with dynamic access control
class CRAccessState {
  /// Whether this progression level has been discovered (permanent once set)
  final bool discovered;

  /// Whether access to this level is currently active based on hysteresis logic
  final bool accessActive;

  const CRAccessState({
    required this.discovered,
    required this.accessActive,
  });

  /// Create an initial state (not discovered, not active)
  factory CRAccessState.initial() {
    return const CRAccessState(
      discovered: false,
      accessActive: false,
    );
  }

  /// Copy with method for immutability
  CRAccessState copyWith({
    bool? discovered,
    bool? accessActive,
  }) {
    return CRAccessState(
      discovered: discovered ?? this.discovered,
      accessActive: accessActive ?? this.accessActive,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'discovered': discovered,
      'accessActive': accessActive,
    };
  }

  /// Create from JSON
  factory CRAccessState.fromJson(Map<String, dynamic> json) {
    return CRAccessState(
      discovered: json['discovered'] as bool? ?? false,
      accessActive: json['accessActive'] as bool? ?? false,
    );
  }
}

/// Configuration for CR access level thresholds and access control parameters
class CRAccessConfig {
  /// Credit threshold for each progression level
  static const int level1Threshold = 5000;
  static const int level2Threshold = 10000;
  static const int level3Threshold = 18000;
  static const int level4Threshold = 25000;

  /// Hysteresis thresholds for access control (as percentages of milestone)
  static const double lockThresholdPercent = 0.60; // 60%
  static const double reactivateThresholdPercent = 0.80; // 80%

  /// All progression level thresholds in order
  static const List<int> allThresholds = [
    level1Threshold,
    level2Threshold,
    level3Threshold,
    level4Threshold,
  ];

  /// Get threshold for a specific progression level (1-based)
  static int getThreshold(int level) {
    if (level < 1 || level > allThresholds.length) {
      throw ArgumentError('Invalid progression level: $level');
    }
    return allThresholds[level - 1];
  }

  /// Calculate the lock threshold (60% of milestone) for a progression level
  static int getLockThreshold(int level) {
    return (getThreshold(level) * lockThresholdPercent).toInt();
  }

  /// Calculate the reactivate threshold (80% of milestone) for a progression level
  static int getReactivateThreshold(int level) {
    return (getThreshold(level) * reactivateThresholdPercent).toInt();
  }

  /// Determine if access should be active based on current credits and previous state
  /// Implements hysteresis to prevent flickering
  static bool calculateAccessActive(
    int currentCredits,
    int levelThreshold,
    bool wasActive,
  ) {
    if (currentCredits >= levelThreshold) {
      // Full balance: always active
      return true;
    }

    final lockThreshold = (levelThreshold * lockThresholdPercent).toInt();
    final reactivateThreshold =
        (levelThreshold * reactivateThresholdPercent).toInt();

    if (wasActive) {
      // Currently active: stay active until drops below lock threshold (60%)
      return currentCredits >= lockThreshold;
    } else {
      // Currently inactive: reactivate only if reaches 80%
      return currentCredits >= reactivateThreshold;
    }
  }
}
