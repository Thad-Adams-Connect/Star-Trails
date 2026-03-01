// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'dart:math';
import '../data/wisdom_entries.dart';

/// Manages "Words of Wisdom" selection, cooldown, and display logic.
/// Provides contextual wisdom based on gameplay events.
class WisdomEngine {
  final Random _random = Random();
  final Map<String, DateTime> _lastShownTimestamps = {};
  
  /// Track wisdom shown in current session (for logbook display)
  final List<DisplayedWisdom> _sessionWisdom = [];

  /// Get all wisdom displayed this session
  List<DisplayedWisdom> get sessionWisdom => List.unmodifiable(_sessionWisdom);

  /// Clear session wisdom (call when starting new game)
  void clearSessionWisdom() {
    _sessionWisdom.clear();
  }

  /// Select contextual wisdom based on tags.
  /// Returns null if on cooldown or no matching wisdom found.
  WisdomEntry? selectWisdom(List<String> contextTags) {
    if (contextTags.isEmpty) return null;

    // Filter wisdom matching any of the context tags
    final candidates = grade4to6Wisdom.where((wisdom) {
      return wisdom.tags.any((tag) => contextTags.contains(tag));
    }).toList();

    if (candidates.isEmpty) return null;

    // Filter out wisdom on cooldown
    final now = DateTime.now();
    final availableWisdom = candidates.where((wisdom) {
      final lastShown = _lastShownTimestamps[wisdom.id];
      if (lastShown == null) return true;
      
      final secondsSinceShown = now.difference(lastShown).inSeconds;
      return secondsSinceShown >= wisdom.minCooldownSeconds;
    }).toList();

    if (availableWisdom.isEmpty) return null;

    // Randomly select from available wisdom
    final selected = availableWisdom[_random.nextInt(availableWisdom.length)];
    
    // Record timestamp
    _lastShownTimestamps[selected.id] = now;

    return selected;
  }

  /// Mark wisdom as shown and optionally saved to logbook.
  /// Call this when displaying wisdom to player.
  void markWisdomShown(WisdomEntry wisdom, {bool savedToLogbook = false}) {
    _lastShownTimestamps[wisdom.id] = DateTime.now();
    
    _sessionWisdom.add(DisplayedWisdom(
      entry: wisdom,
      timestamp: DateTime.now(),
      savedToLogbook: savedToLogbook,
    ));
  }

  /// Get recent wisdom within the last N minutes (for anti-spam)
  List<DisplayedWisdom> getRecentWisdom({int minutes = 10}) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    return _sessionWisdom
        .where((dw) => dw.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Check if wisdom can be shown (respects global cooldown)
  bool canShowWisdom({int minMinutesBetween = 3}) {
    if (_sessionWisdom.isEmpty) return true;
    
    final lastShown = _sessionWisdom.last.timestamp;
    final minutesSince = DateTime.now().difference(lastShown).inMinutes;
    
    return minutesSince >= minMinutesBetween;
  }

  /// Get all wisdom entries for logbook viewing (ignores cooldown)
  List<WisdomEntry> getAllWisdom() {
    return List.unmodifiable(grade4to6Wisdom);
  }

  /// Get wisdom saved to logbook in current session
  List<DisplayedWisdom> getSavedWisdom() {
    return _sessionWisdom.where((dw) => dw.savedToLogbook).toList();
  }
}

/// Represents a wisdom entry that was displayed during gameplay
class DisplayedWisdom {
  final WisdomEntry entry;
  final DateTime timestamp;
  final bool savedToLogbook;

  const DisplayedWisdom({
    required this.entry,
    required this.timestamp,
    required this.savedToLogbook,
  });
}
