// Star Trails
// Copyright (c) 2026 Ubertas Lab, LLC.
// All Rights Reserved.

class AppVersion {
  const AppVersion._();

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

    return '0.0.0';
  }

  static String get buildNumber {
    final parsedBuildNumber = _fullVersionMatch?.group(3);
    if (parsedBuildNumber != null && parsedBuildNumber.isNotEmpty) {
      return parsedBuildNumber;
    }

    if (_rawBuildNumber.isNotEmpty) {
      return _rawBuildNumber;
    }

    return '0';
  }

  static String get fullVersion {
    if (_rawFullVersion.isNotEmpty) {
      return _rawFullVersion;
    }

    return '$editionCode-$baseVersion+$buildNumber';
  }
}
