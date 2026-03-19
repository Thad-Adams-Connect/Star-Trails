// Star Trails™
// Copyright © 2026 Ubertas Lab, LLC.
// All Rights Reserved.
// Unauthorized copying, modification, distribution, or reverse engineering prohibited.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'providers/game_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'utils/app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(
    windows: true,
    linux: true,
  );
  await AppVersion.initialize();
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
        home: const SplashScreen(),
      ),
    );
  }
}
