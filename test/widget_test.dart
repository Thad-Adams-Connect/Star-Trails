// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_trails/main.dart';
import 'package:star_trails/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App builds and shows splash, menu, or loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StarTrailsApp());
    await tester.pump();

    final hasSplash = find.byType(SplashScreen).evaluate().isNotEmpty;
    final hasLoading =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasTitle = find.text('STAR TRAILS').evaluate().isNotEmpty;

    expect(hasSplash || hasLoading || hasTitle, isTrue);
  });
}
