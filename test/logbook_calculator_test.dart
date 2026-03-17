// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_trails/providers/game_provider.dart';
import 'package:star_trails/screens/logbook_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('calculator history stays hidden when there are no calculations',
      (tester) async {
    final provider = await _createProvider();

    await _pumpCalculatorTab(tester, provider);

    expect(find.text('Calculation History'), findsNothing);
    expect(
      find.textContaining('No saved calculations yet'),
      findsNothing,
    );
  });

  testWidgets('calculator history keeps the original calculation numbering',
      (tester) async {
    final provider = await _createProvider(
      calculations: const [
        _SeedCalculation(buyPrice: 10, sellPrice: 16, quantity: 2),
        _SeedCalculation(buyPrice: 20, sellPrice: 29, quantity: 3),
      ],
    );

    await _pumpCalculatorTab(tester, provider);

    expect(find.text('Calculation 2'), findsOneWidget);
    expect(find.text('Buy: 20 cr  |  Sell: 29 cr  |  Qty: 3'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Calculation 1'), findsOneWidget);
    expect(find.text('Buy: 10 cr  |  Sell: 16 cr  |  Qty: 2'), findsOneWidget);
  });

  testWidgets('arrow keys load calculator history into the fields',
      (tester) async {
    final provider = await _createProvider(
      calculations: const [
        _SeedCalculation(buyPrice: 11, sellPrice: 18, quantity: 2),
        _SeedCalculation(buyPrice: 25, sellPrice: 37, quantity: 4),
        _SeedCalculation(buyPrice: 30, sellPrice: 42, quantity: 5),
      ],
    );

    await _pumpCalculatorTab(tester, provider);

    final fields = find.byType(TextField);
    await tester.tap(fields.at(0));
    await tester.pump();

    // First up arrow loads the most recent calculation
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      '30',
    );
    expect(
      tester.widget<TextField>(fields.at(1)).controller!.text,
      '42',
    );
    expect(
      tester.widget<TextField>(fields.at(2)).controller!.text,
      '5',
    );

    // Second up arrow goes to the previous calculation
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      '25',
    );
    expect(
      tester.widget<TextField>(fields.at(1)).controller!.text,
      '37',
    );
    expect(
      tester.widget<TextField>(fields.at(2)).controller!.text,
      '4',
    );

    // Third up arrow goes even further back
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      '11',
    );
    expect(
      tester.widget<TextField>(fields.at(1)).controller!.text,
      '18',
    );
    expect(
      tester.widget<TextField>(fields.at(2)).controller!.text,
      '2',
    );

    // Down arrow goes back to more recent
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      '25',
    );
    expect(
      tester.widget<TextField>(fields.at(1)).controller!.text,
      '37',
    );
    expect(
      tester.widget<TextField>(fields.at(2)).controller!.text,
      '4',
    );
  });
}

Future<GameProvider> _createProvider({
  List<_SeedCalculation> calculations = const [],
}) async {
  final provider = GameProvider();
  await provider.dashboard.initialize();
  await provider.dashboard.startSession();

  for (final calculation in calculations) {
    await provider.dashboard.addTradingCalculation(
      buyPrice: calculation.buyPrice,
      sellPrice: calculation.sellPrice,
      quantity: calculation.quantity,
    );
  }

  return provider;
}

Future<void> _pumpCalculatorTab(
  WidgetTester tester,
  GameProvider provider,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: LogbookScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('CALCULATORS'));
  await tester.pumpAndSettle();
}

class _SeedCalculation {
  final int buyPrice;
  final int sellPrice;
  final int quantity;

  const _SeedCalculation({
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
  });
}
