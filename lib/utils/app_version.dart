import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Star Trails
// Copyright (c) 2026 Ubertas Lab, LLC.
// All Rights Reserved.

class AppVersion {
  const AppVersion._();

  // Cached version config loaded from assets at runtime
  static Map<String, String> _cachedVersions = {};

  // Development fallback version from pubspec.yaml
  static const String _developmentVersion = '1.0.1+1';

  static const String _rawEdition = String.fromEnvironment('APP_EDITION');
  static const String _rawFullVersion = String.fromEnvironment('FULL_VERSION');
  static const String _rawBuildName =
      String.fromEnvironment('FLUTTER_BUILD_NAME');
  static const String _rawBuildNumber =
      String.fromEnvironment('FLUTTER_BUILD_NUMBER');

  static final RegExp _fullVersionPattern =
      RegExp(r'^([A-Z0-9]+)-(\d+\.\d+\.\d+)(?:\+(\d+))?$');

  static final Match? _fullVersionMatch =
      _fullVersionPattern.firstMatch(_rawFullVersion.trim());

  /// Load config from assets. Called automatically on first access, but can be
  /// called manually to refresh version data (e.g., when SettingsScreen opens).
  static Future<void> _loadConfig({String? configPath}) async {
    try {
      final assetPath = configPath ?? 'config/version_config.json';
      final configJson = await rootBundle.loadString(assetPath);
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      final versions = config['versions'] as Map<String, dynamic>?;

      if (versions != null) {
        _cachedVersions = versions.cast<String, String>();
      }
    } catch (e) {
      // Silently fail and use fallbacks
      debugPrint('AppVersion: Could not load version config: $e');
    }
  }

  /// Refresh version data from config file. Call this before displaying
  /// version info (e.g., in SettingsScreen.initState) to ensure current version.
  static Future<void> refresh({String? configPath}) async {
    await _loadConfig(configPath: configPath);
  }

  /// Initialize AppVersion by loading config from assets.
  /// Call this from main() before running the app.
  static Future<void> initialize({String? configPath}) async {
    await _loadConfig(configPath: configPath);
  }

  static String get editionCode {
    if (_rawEdition.isNotEmpty) {
      return _rawEdition.toUpperCase();
    }

    final parsedEdition = _fullVersionMatch?.group(1);
    if (parsedEdition != null && parsedEdition.isNotEmpty) {
      return parsedEdition.toUpperCase();
    }

    return 'PUB';
  }

  static String get editionName {
    switch (editionCode) {
      case 'PUB':
        return 'Public Edition';
      case 'EDU46':
        return 'Educational Edition (Grades 4-6)';
      case 'EDU79':
        return 'Educational Edition (Grades 7-9)';
      case 'EDU1012':
        return 'Educational Edition (Grades 10-12)';
      default:
        return '$editionCode Edition';
    }
  }

  static String get baseVersion {
    final parsedBaseVersion = _fullVersionMatch?.group(2);
    if (parsedBaseVersion != null && parsedBaseVersion.isNotEmpty) {
      return parsedBaseVersion;
    }

    if (_rawBuildName.isNotEmpty) {
      return _rawBuildName;
    }

    // Check if we have a cached version from config
    if (_cachedVersions.isNotEmpty) {
      final cachedVersion = _cachedVersions[editionCode];
      if (cachedVersion != null) {
        return cachedVersion;
      }
    }

    // Development fallback: extract version from pubspec.yaml format
    return _developmentVersion.split('+').first;
  }

  static String get buildNumber {
    final parsedBuildNumber = _fullVersionMatch?.group(3);
    if (parsedBuildNumber != null && parsedBuildNumber.isNotEmpty) {
      return parsedBuildNumber;
    }

    if (_rawBuildNumber.isNotEmpty) {
      return _rawBuildNumber;
    }

    // Development fallback: extract build number from pubspec.yaml format
    return _developmentVersion.split('+').length > 1
        ? _developmentVersion.split('+')[1]
        : '0';
  }

  static String get fullVersion {
    if (_rawFullVersion.isNotEmpty) {
      return _rawFullVersion;
    }

    // Development fallback: construct from components
    return '$editionCode-$baseVersion+$buildNumber';
  }
}
