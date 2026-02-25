// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_trails/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App builds and shows menu or loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StarTrailsApp());
    await tester.pump();

    // Either loading indicator (while SharedPreferences loads) or menu content.
    final hasLoading =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasTitle = find.text('STAR TRAILS').evaluate().isNotEmpty;
    expect(hasLoading || hasTitle, isTrue);
  });
}
