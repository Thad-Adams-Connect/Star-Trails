// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter_test/flutter_test.dart';
import 'package:star_trails/models/cr_access_state.dart';

void main() {
  group('CRAccessState Tests', () {
    test('Initial state should not be discovered or active', () {
      final state = CRAccessState.initial();
      expect(state.discovered, false);
      expect(state.accessActive, false);
    });

    test('copyWith should update discovered flag', () {
      final state = CRAccessState.initial();
      final updated = state.copyWith(discovered: true);
      expect(updated.discovered, true);
      expect(updated.accessActive, false);
    });

    test('copyWith should update accessActive flag', () {
      final state = CRAccessState.initial();
      final updated = state.copyWith(accessActive: true);
      expect(updated.discovered, false);
      expect(updated.accessActive, true);
    });

    test('JSON serialization round-trip should work', () {
      final state = CRAccessState(discovered: true, accessActive: true);
      final json = state.toJson();
      final restored = CRAccessState.fromJson(json);
      
      expect(restored.discovered, state.discovered);
      expect(restored.accessActive, state.accessActive);
    });
  });

  group('CRAccessConfig Tests', () {
    test('Access level thresholds should be correct', () {
      expect(CRAccessConfig.level1Threshold, 5000);
      expect(CRAccessConfig.level2Threshold, 10000);
      expect(CRAccessConfig.level3Threshold, 18000);
      expect(CRAccessConfig.level4Threshold, 25000);
    });

    test('getThreshold should return correct values', () {
      expect(CRAccessConfig.getThreshold(1), 5000);
      expect(CRAccessConfig.getThreshold(2), 10000);
      expect(CRAccessConfig.getThreshold(3), 18000);
      expect(CRAccessConfig.getThreshold(4), 25000);
    });

    test('getLockThreshold should be 60% of milestone', () {
      expect(CRAccessConfig.getLockThreshold(1), 3000); // 5000 * 0.60
      expect(CRAccessConfig.getLockThreshold(2), 6000); // 10000 * 0.60
      expect(CRAccessConfig.getLockThreshold(3), 10800); // 18000 * 0.60
      expect(CRAccessConfig.getLockThreshold(4), 15000); // 25000 * 0.60
    });

    test('getReactivateThreshold should be 80% of milestone', () {
      expect(CRAccessConfig.getReactivateThreshold(1), 4000); // 5000 * 0.80
      expect(CRAccessConfig.getReactivateThreshold(2), 8000); // 10000 * 0.80
      expect(CRAccessConfig.getReactivateThreshold(3), 14400); // 18000 * 0.80
      expect(CRAccessConfig.getReactivateThreshold(4), 20000); // 25000 * 0.80
    });

    // Hysteresis logic tests
    test('Access should activate at 100% of threshold', () {
      final isActive = CRAccessConfig.calculateAccessActive(
        5000, // currentCredits (exactly at threshold)
        5000, // levelThreshold
        false, // was not active
      );
      expect(isActive, true);
    });

    test('Access should stay active until below 60% lock threshold', () {
      // At 3500 credits with was active true should still be active (above 3000)
      final isActive = CRAccessConfig.calculateAccessActive(
        3500, // currentCredits (above lock threshold)
        5000, // levelThreshold
        true, // was active
      );
      expect(isActive, true);
    });

    test('Access should deactivate when falling below 60% lock threshold', () {
      // At 2999 credits with was active true should become inactive
      final isActive = CRAccessConfig.calculateAccessActive(
        2999, // currentCredits (below lock threshold 3000)
        5000, // levelThreshold
        true, // was active
      );
      expect(isActive, false);
    });

    test('Access should not reactivate until reaching 80% reactivate threshold', () {
      // At 3999 credits with was active false should stay inactive (below 4000)
      final isActive = CRAccessConfig.calculateAccessActive(
        3999, // currentCredits (below reactivate threshold)
        5000, // levelThreshold
        false, // was not active
      );
      expect(isActive, false);
    });

    test('Access should reactivate when reaching 80% reactivate threshold', () {
      // At 4000 credits with was active false should reactivate
      final isActive = CRAccessConfig.calculateAccessActive(
        4000, // currentCredits (exactly at reactivate threshold)
        5000, // levelThreshold
        false, // was not active
      );
      expect(isActive, true);
    });

    test('Hysteresis prevents flickering between lock and reactivate thresholds', () {
      // Active path: 5000 -> 3500 (stays active) -> 2999 (deactivates)
      var isActive = true;
      isActive = CRAccessConfig.calculateAccessActive(3500, 5000, isActive);
      expect(isActive, true);

      isActive = CRAccessConfig.calculateAccessActive(2999, 5000, isActive);
      expect(isActive, false);

      // Inactive path: 2999 -> 3100 (stays inactive) -> 4000 (reactivates)
      isActive = CRAccessConfig.calculateAccessActive(3100, 5000, isActive);
      expect(isActive, false);

      isActive = CRAccessConfig.calculateAccessActive(4000, 5000, isActive);
      expect(isActive, true);
    });
  });
}
