// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/menu_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const StarTrailsApp());
}

class StarTrailsApp extends StatelessWidget {
  const StarTrailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Star Trails',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppTheme.background,
          fontFamily: 'monospace',
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.phosphorGreen,
            surface: AppTheme.surface,
            onSurface: AppTheme.phosphorGreenBright,
          ),
        ),
        home: const MenuScreen(),
      ),
    );
  }
}
