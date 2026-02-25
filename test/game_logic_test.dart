// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_trails/models/game_state.dart';
import 'package:star_trails/models/planet.dart';
import 'package:star_trails/providers/game_provider.dart';
import 'package:star_trails/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('BID/ASK Pricing Tests', () {
    test('BID is always less than ASK for all planets and items', () {
      for (var planetId in GameConstants.planetIds) {
        final planet = Planet(id: planetId);
        for (var itemId in GameConstants.itemIds) {
          final bid = planet.getBidPrice(itemId);
          final ask = planet.getAskPrice(itemId);
          expect(bid, lessThan(ask),
              reason:
                  'Planet $planetId, Item $itemId: bid=$bid should be < ask=$ask');
        }
      }
    });

    test('Buy then sell same item on same planet results in loss', () {
      final state = GameState.initial();
      final planet = state.currentPlanet;
      const item = 'Food';

      final askPrice = planet.getAskPrice(item);
      final bidPrice = planet.getBidPrice(item);

      final costToBuy = askPrice * 5;
      final earnedFromSell = bidPrice * 5;

      expect(earnedFromSell, lessThan(costToBuy),
          reason:
              'Selling should earn less than buying cost to prevent arbitrage');
    });
  });

  group('Market Fatigue Tests', () {
    test('Selling decreases demand index', () {
      final planet = Planet(id: 'HELIOS REACH');
      const item = 'Food';

      final initialDemand = planet.demandIndex[item];
      final newPlanet = planet.decreaseDemand(item);
      final newDemand = newPlanet.demandIndex[item];

      expect(newDemand, equals(initialDemand! - 1),
          reason: 'Demand should decrease by 1 after selling');
    });

    test('Demand index never goes below 0', () {
      var planet = Planet(id: 'HELIOS REACH');
      const item = 'Food';

      for (int i = 0; i < 10; i++) {
        planet = planet.decreaseDemand(item);
      }

      expect(planet.demandIndex[item], greaterThanOrEqualTo(0),
          reason: 'Demand should never go below 0');
    });

    test('Arriving at planet increases all demand indices', () {
      final planet = Planet(id: 'KESTREL BELT');
      final newPlanet = planet.increaseDemandAll();

      for (var item in GameConstants.itemIds) {
        expect(newPlanet.demandIndex[item],
            greaterThanOrEqualTo(planet.demandIndex[item]!),
            reason: 'Demand for $item should increase or stay at max');
      }
    });

    test('Demand index never goes above 3', () {
      var planet = Planet(id: 'HELIOS REACH');

      for (int i = 0; i < 10; i++) {
        planet = planet.increaseDemandAll();
      }

      for (var item in GameConstants.itemIds) {
        expect(planet.demandIndex[item], lessThanOrEqualTo(3),
            reason: 'Demand for $item should never exceed 3');
      }
    });

    test('Repeated selling decreases bid price', () {
      var planet = Planet(id: 'HELIOS REACH');
      const item = 'Food';

      final initialBid = planet.getBidPrice(item);

      planet = planet.decreaseDemand(item);
      final secondBid = planet.getBidPrice(item);

      planet = planet.decreaseDemand(item);
      final thirdBid = planet.getBidPrice(item);

      expect(secondBid, lessThanOrEqualTo(initialBid),
          reason: 'Bid should decrease after first sale');
      expect(thirdBid, lessThanOrEqualTo(secondBid),
          reason: 'Bid should continue decreasing after second sale');
    });

    test('Bid price adjusts correctly based on demand levels', () {
      const item = 'Food';
      final marketPrice = GameConstants.getMarketPrice('HELIOS REACH', item);
      final baseAsk = marketPrice.buy;
      final baseSell = marketPrice.sell;

      for (int demand = 0; demand <= 3; demand++) {
        final planet = Planet(id: 'HELIOS REACH', demandIndex: {
          'Food': demand,
          'Ore': 3,
          'Medicine': 3,
        });

        final bid = planet.getBidPrice(item);
        final ask = planet.getAskPrice(item);

        expect(bid, lessThan(ask),
            reason: 'Bid must be less than ask at demand=$demand');

        if (demand == 0) {
          final expectedBid = (baseSell * 0.9).floor();
          expect(bid, equals(expectedBid),
              reason: 'At demand=0, bid should be 90% of base sell');
        } else if (demand == 1) {
          final expectedBid = (baseSell * 0.95).floor();
          expect(bid, equals(expectedBid),
              reason: 'At demand=1, bid should be 95% of base sell');
        } else {
          var expectedBid = baseSell;
          if (expectedBid >= baseAsk) {
            expectedBid = baseAsk - 1;
          }
          expect(bid, equals(expectedBid),
              reason: 'At demand=$demand, bid should be at base sell cap');
        }
      }
    });
  });

  group('Game State Tests', () {
    test('Initial state is correct', () {
      final state = GameState.initial();

      expect(state.location, equals('HELIOS REACH'));
      expect(state.fuel, equals(10));
      expect(state.credits, equals(1000));
      expect(state.cargoUsed, equals(0));
      expect(state.cargoAvailable, equals(10));
    });

    test('Cargo calculations are correct', () {
      final state = GameState.initial();
      final newCargo = Map<String, int>.from(state.cargo);
      newCargo['Food'] = 3;
      newCargo['Ore'] = 5;

      final newState = state.copyWith(cargo: newCargo);

      expect(newState.cargoUsed, equals(8));
      expect(newState.cargoAvailable, equals(2));
    });
  });

  group('Persistence Tests', () {
    test('GameState serializes and deserializes correctly', () {
      final state = GameState.initial();
      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.location, equals(state.location));
      expect(restored.fuel, equals(state.fuel));
      expect(restored.credits, equals(state.credits));
      expect(restored.cargo, equals(state.cargo));
    });

    test('Planet serializes and deserializes correctly', () {
      final planet = Planet(id: 'HELIOS REACH');
      final json = planet.toJson();
      final restored = Planet.fromJson(json);

      expect(restored.id, equals(planet.id));
      expect(restored.demandIndex, equals(planet.demandIndex));
    });
  });

  group('Game flow (provider commands)', () {
    test('help command adds command list to log', () async {
      final provider = GameProvider();
      await provider.processCommand('help');
      final log = provider.state.log;
      expect(log.any((line) => line.contains('COMMANDS')), isTrue);
      expect(log.any((line) => line.contains('buy')), isTrue);
      expect(log.any((line) => line.contains('travel')), isTrue);
    });

    test('status command shows location and fuel', () async {
      final provider = GameProvider();
      await provider.processCommand('status');
      final log = provider.state.log;
      expect(log.any((line) => line.contains('LOCATION: HELIOS REACH')), isTrue);
      expect(
          log.any((line) => line.contains(
              'FUEL: ${GameConstants.initialFuel}/${provider.state.getFuelCapacity()}')),
          isTrue);
    });

    test('buy food 1 decreases credits and adds cargo', () async {
      final provider = GameProvider();
      final initialCredits = provider.state.credits;
      await provider.processCommand('buy food 1');
      expect(provider.state.credits, lessThan(initialCredits));
      expect(provider.state.cargo['Food'], equals(1));
      expect(provider.state.cargoUsed, equals(1));
    });

    test('travel kestrel belt changes location and uses fuel', () async {
      final provider = GameProvider();
      await provider.processCommand('travel kestrel belt');
      expect(provider.state.location, equals('KESTREL BELT'));
      expect(provider.state.fuel, equals(GameConstants.initialFuel - 3));
    });

    test('sell reduces cargo and increases credits', () async {
      final provider = GameProvider();
      await provider.processCommand('buy food 2');
      final creditsAfterBuy = provider.state.credits;
      await provider.processCommand('sell food 1');
      expect(provider.state.cargo['Food'], equals(1));
      expect(provider.state.credits, greaterThan(creditsAfterBuy));
    });

    test('unknown command adds error message to log', () async {
      final provider = GameProvider();
      final logLengthBefore = provider.state.log.length;
      await provider.processCommand('xyz');
      expect(provider.state.log.length, greaterThan(logLengthBefore));
      expect(provider.state.log.last, contains('Unknown command'));
    });
  });

  group('Ship Upgrade Tests', () {
    test('initial fuel capacity is 10', () {
      final state = GameState.initial();
      expect(state.getFuelCapacity(), equals(10));
    });

    test('initial cargo capacity is 10', () {
      final state = GameState.initial();
      expect(state.getCargoCapacity(), equals(10));
    });

    test('upgrade command shows available upgrades', () async {
      final provider = GameProvider();
      await provider.processCommand('upgrade');
      final log = provider.state.log;
      expect(log.any((line) => line.contains('fuel:')), isTrue);
      expect(log.any((line) => line.contains('cargo:')), isTrue);
    });

    test('fuel upgrade from tier 0 to tier 1 increases capacity', () async {
      final provider = GameProvider();
      final initialCapacity = provider.state.getFuelCapacity();
      await provider.processCommand('upgrade fuel 1');
      expect(provider.state.shipUpgrades['fuel']!.currentTier, equals(1));
      expect(provider.state.getFuelCapacity(), equals(15));
      expect(provider.state.getFuelCapacity(), greaterThan(initialCapacity));
    });

    test('cargo upgrade from tier 0 to tier 1 increases capacity', () async {
      final provider = GameProvider();
      final initialCapacity = provider.state.getCargoCapacity();
      await provider.processCommand('upgrade cargo 1');
      expect(provider.state.shipUpgrades['cargo']!.currentTier, equals(1));
      expect(provider.state.getCargoCapacity(), equals(15));
      expect(provider.state.getCargoCapacity(), greaterThan(initialCapacity));
    });

    test('fuel upgrade to tier 2 increases capacity to 20', () async {
      final provider = GameProvider();
      await provider.processCommand('upgrade fuel 1');
      await provider.processCommand('upgrade fuel 2');
      expect(provider.state.shipUpgrades['fuel']!.currentTier, equals(2));
      expect(provider.state.getFuelCapacity(), equals(20));
    });

    test('cargo upgrade to tier 2 increases capacity to 20', () async {
      final provider = GameProvider();
      await provider.processCommand('upgrade cargo 1');
      await provider.processCommand('upgrade cargo 2');
      expect(provider.state.shipUpgrades['cargo']!.currentTier, equals(2));
      expect(provider.state.getCargoCapacity(), equals(20));
    });

    test('cannot downgrade upgrades', () async {
      final provider = GameProvider();
      await provider.processCommand('upgrade fuel 1');
      final creditsAfterUpgrade = provider.state.credits;
      await provider.processCommand('upgrade fuel 0');
      expect(provider.state.credits, equals(creditsAfterUpgrade));
      expect(provider.state.shipUpgrades['fuel']!.currentTier, equals(1));
    });

    test('upgrade costs are deducted from credits', () async {
      final provider = GameProvider();
      final initialCredits = provider.state.credits;
      await provider.processCommand('upgrade fuel 1');
      final fuelCost = GameConstants.getUpgradeCost('fuel', 1);
      expect(provider.state.credits, equals(initialCredits - fuelCost));
    });
  });

  group('Credits Milestone Progression', () {
    test('tracks highest on-hand credits reached', () {
      final state = GameState.initial();
      final increased = state.copyWith(credits: 1800);

      expect(increased.highestCreditsReached, equals(1800));
    });

    test('does not lower highest credits or level when credits drop', () {
      final state = GameState.initial().copyWith(credits: 12000);
      final levelAtPeak = state.unlockedLevel;

      final dropped = state.copyWith(credits: 900);

      expect(dropped.highestCreditsReached, equals(12000));
      expect(dropped.unlockedLevel, equals(levelAtPeak));
    });

    test('level unlocks are based on highest on-hand credits, not lifetime earnings', () {
      final state = GameState.initial().copyWith(
        credits: 900,
        totalCreditsEarned: 50000,
        lifetimeCreditsEarned: 75000,
      );

      expect(state.highestCreditsReached, equals(GameConstants.initialCredits));
      expect(state.unlockedLevel,
          equals(GameConstants.getUnlockedLevelForHighestCredits(GameConstants.initialCredits)));
    });

    test('final milestone is reached at 25000 on-hand credits', () {
      final state = GameState.initial().copyWith(credits: 25000);

      expect(state.reachedFinalCreditMilestone, isTrue);
      expect(state.highestCreditsReached, equals(25000));
      expect(state.unlockedLevel, equals(GameConstants.creditLevelMilestones.length));
    });
  });
}
