# Star Trails - Build and Release Guide

Complete step-by-step instructions for managing editions, versions, and building for all platforms.

---

## Table of Contents

1. [Edition Management](#edition-management)
2. [Version Management](#version-management)
3. [Platform Builds](#platform-builds)
4. [Multi-Edition Release Workflow](#multi-edition-release-workflow)
5. [Troubleshooting](#troubleshooting)

---

## Edition Management

### View Current Editions

```bash
python core/version_manager/edition_detector.py
```

Output: Current active edition (e.g., `PUB`)

### List All Supported Editions

```bash
python -c "from core.version_manager import load_supported_editions; editions = load_supported_editions('config/editions.json'); print('\n'.join(e.value for e in editions))"
```

Output:
```
PUB
EDU46
EDU79
EDU1012
```

### Add a New Edition

**Step 1**: Update `config/editions.json`

```json
{
  "supported_editions": [
    "PUB",
    "EDU46",
    "EDU79",
    "EDU1012",
    "CUSTOM"
  ]
}
```

**Step 2**: Add version to `config/version_config.json`

```json
{
  "versions": {
    "PUB": "1.0.4",
    "EDU46": "1.0.3",
    "EDU79": "1.0.3",
    "EDU1012": "1.0.3",
    "CUSTOM": "1.0.0"
  }
}
```

**Step 3**: Add features to `config/features.json`

```json
{
  "CUSTOM": [
    "terminal",
    "logbook",
    "wisdom_system",
    "trading",
    "exploration",
    "ship_upgrades",
    "reputation",
    "cr_access"
  ]
}
```

**Step 4**: Create build profile `build_profiles/custom.json`

```json
{
  "edition": "CUSTOM",
  "display_name": "Star Trails - Custom Edition",
  "version_prefix": "CUSTOM",
  "content_path": "content/custom",
  "features": [
    "terminal",
    "logbook",
    "wisdom_system",
    "trading",
    "exploration",
    "ship_upgrades",
    "reputation",
    "cr_access"
  ],
  "difficulty": {
    "starting_credits": 1000,
    "fuel_cost_multiplier": 1.0,
    "price_volatility": 1.0,
    "enable_route_exploitation_limits": true
  },
  "branding": {
    "app_name": "Star Trails",
    "short_name": "StarTrails-CUSTOM",
    "bundle_id": "com.ubertaslab.startrails.custom",
    "theme_color": "#1a237e"
  },
  "build_targets": [
    "android",
    "ios",
    "windows",
    "macos",
    "linux",
    "web"
  ]
}
```

**Step 5**: Create content directory structure

```bash
mkdir -p content/custom/{missions,wisdom,history}
touch content/custom/missions/.gitkeep
touch content/custom/wisdom/.gitkeep
touch content/custom/history/.gitkeep
```

**Step 6**: Update `content_manifest.json`

```json
{
  "CUSTOM": {
    "content_path": "content/custom",
    "missions": {
      "total": 0,
      "categories": []
    },
    "wisdom": {
      "total": 0,
      "path": "content/custom/wisdom/"
    },
    "history": {
      "total": 0,
      "path": "content/custom/history/"
    }
  }
}
```

**Step 7**: Validate configuration

```bash
python -c "from core.version_manager import ConfigValidator; ConfigValidator.print_validation_report()"
```

Expected: `✓ VALID: Configuration Validation - All configuration files are valid and consistent.`

---

## Version Management

### Check Current Versions

```bash
python -c "from core.version_manager import load_version_config, load_supported_editions; versions = load_version_config('config/version_config.json', load_supported_editions('config/editions.json')); [print(f'{v.edition.value}: {v.base_version}') for v in versions.values()]"
```

Output:
```
PUB: 1.0.4
EDU46: 1.0.3
EDU79: 1.0.3
EDU1012: 1.0.3
```

### View Version History

```bash
python -c "from core.version_manager import VersionHistoryManager; VersionHistoryManager.print_history_report()"
```

Output:
```
============================================================
VERSION HISTORY REPORT
============================================================

EDU1012:
  1. 1.0.0
  2. 1.0.3 (latest)

EDU46:
  1. 1.0.0
  2. 1.0.3 (latest)
...
```

### Bump Patch Version (All Editions)

Bumps patch: 1.0.3 → 1.0.4

```bash
python scripts/bump_version.py patch
```

Output:
```
PUB: 1.0.4 -> 1.0.5
EDU46: 1.0.3 -> 1.0.4
EDU79: 1.0.3 -> 1.0.4
EDU1012: 1.0.3 -> 1.0.4
```

### Bump Minor Version (All Editions)

Bumps minor, resets patch: 1.0.3 → 1.1.0

```bash
python scripts/bump_version.py minor
```

### Bump Major Version (All Editions)

Bumps major, resets minor/patch: 1.0.3 → 2.0.0

```bash
python scripts/bump_version.py major
```

### Bump Version for Specific Edition

```bash
# Patch only for PUB
python scripts/bump_version.py patch --edition PUB

# Minor only for EDU46
python scripts/bump_version.py minor --edition EDU46

# Major only for EDU79
python scripts/bump_version.py major --edition EDU79
```

### Auto-Versioning with Git Hooks

After committing code changes to `lib/` or `core/`, hooks automatically bump patch for all editions.

Setup (one-time):

```bash
python scripts/setup_auto_versioning.py
```

To skip auto-bump on a specific commit:

```bash
git commit --no-verify
```

---

## Platform Builds

### Prerequisites

```bash
# Install Flutter and dependencies
flutter pub get

# Verify setup
flutter doctor
```

### Generate Version Payload (Required for All Builds)

For default edition (PUB):

```bash
python build/build_version_generator.py --use-manifest --validate-config
```

For specific edition:

```bash
python build/edition_build_generator.py --edition EDU46 --validate-config
```

Export environment variables:

```bash
export $(python build/edition_build_generator.py --edition PUB --validate-config)
```

Verify (PowerShell):

```powershell
$env:EDITION
$env:VERSION
$env:FULL_VERSION
$env:FLUTTER_BUILD_NAME
$env:FLUTTER_BUILD_NUMBER
```

### Android Build

**Debug Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build apk \
  --debug \
  --build-name "$FLUTTER_BUILD_NAME" \
  --build-number "$FLUTTER_BUILD_NUMBER" \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build apk \
  --release \
  --build-name "$FLUTTER_BUILD_NAME" \
  --build-number "$FLUTTER_BUILD_NUMBER" \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Sign Release APK** (requires keystore):

```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/.android/release-key.keystore \
  build/app/outputs/flutter-apk/app-release.apk \
  release-key
```

### iOS Build

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build ipa \
  --release \
  --build-name "$FLUTTER_BUILD_NAME" \
  --build-number "$FLUTTER_BUILD_NUMBER" \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/ios/ipa/StarTrails.ipa`

**Upload to TestFlight**:

```bash
xcrun altool --upload-app \
  -f build/ios/ipa/StarTrails.ipa \
  -t ios \
  -u your-apple-id@example.com \
  -p your-app-specific-password
```

### Windows Build

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build windows \
  --release \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/windows/runner/Release/`

**Create Installer** (MSIX):

```bash
flutter build windows --release
# Creates distributable MSIX package
```

### macOS Build

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build macos \
  --release \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/macos/Build/Products/Release/Star Trails.app`

### Linux Build

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build linux \
  --release \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/linux/x64/release/bundle/`

### Web Build

**Release Build**:

```bash
export $(python build/edition_build_generator.py --use-manifest)
flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define APP_EDITION="$EDITION" \
  --dart-define FULL_VERSION="$FULL_VERSION"
```

Output: `build/web/` (ready for static hosting)

---

## Multi-Edition Release Workflow

### Scenario: Release version 2.0.0 for all editions

**Step 1**: Prepare repository

```bash
git checkout main
git pull origin main
```

**Step 2**: Bump major version

```bash
python scripts/bump_version.py major
# All editions updated: X.Y.Z → 2.0.0
```

**Step 3**: Verify versions

```bash
cat config/version_config.json
```

**Step 4**: Test all editions

```bash
flutter test
python -m unittest discover -s tests -p "*_tests.py"
flutter analyze
```

**Step 5**: Commit version changes

```bash
git add config/version_config.json config/version_history.json
git commit -m "Release: version 2.0.0 for all editions"
```

**Step 6**: Tag release

```bash
git tag -a v2.0.0 -m "Star Trails 2.0.0 - All editions"
git push origin main --tags
```

**Step 7**: Build each edition

Create build script `scripts/build_all_editions.sh`:

```bash
#!/bin/bash

EDITIONS=(PUB EDU46 EDU79 EDU1012)
PLATFORMS=(android ios windows macos linux web)

for edition in "${EDITIONS[@]}"; do
  echo "Building $edition..."
  
  # Generate version
  export $(python build/edition_build_generator.py --edition "$edition" --validate-config)
  
  for platform in "${PLATFORMS[@]}"; do
    case "$platform" in
      android)
        flutter build apk --release \
          --build-name "$FLUTTER_BUILD_NAME" \
          --build-number "$FLUTTER_BUILD_NUMBER" \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        cp build/app/outputs/flutter-apk/app-release.apk releases/$EDITION-$VERSION-android.apk
        ;;
      ios)
        flutter build ipa --release \
          --build-name "$FLUTTER_BUILD_NAME" \
          --build-number "$FLUTTER_BUILD_NUMBER" \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        cp build/ios/ipa/StarTrails.ipa releases/$EDITION-$VERSION-ios.ipa
        ;;
      windows)
        flutter build windows --release \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        zip -r releases/$EDITION-$VERSION-windows.zip build/windows/runner/Release/
        ;;
      macos)
        flutter build macos --release \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        zip -r releases/$EDITION-$VERSION-macos.zip build/macos/Build/Products/Release/
        ;;
      linux)
        flutter build linux --release \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        tar -czf releases/$EDITION-$VERSION-linux.tar.gz build/linux/x64/release/bundle/
        ;;
      web)
        flutter build web --release \
          --web-renderer canvaskit \
          --dart-define APP_EDITION="$EDITION" \
          --dart-define FULL_VERSION="$FULL_VERSION"
        zip -r releases/$EDITION-$VERSION-web.zip build/web/
        ;;
    esac
  done
done
```

Run:

```bash
chmod +x scripts/build_all_editions.sh
mkdir -p releases
./scripts/build_all_editions.sh
```

**Step 8**: Verify artifacts

```bash
ls -lh releases/
```

Expected output:
```
PUB-2.0.0-android.apk
PUB-2.0.0-ios.ipa
PUB-2.0.0-windows.zip
...
EDU1012-2.0.0-web.zip
```

**Step 9**: Upload and announce

- Upload APKs to Google Play Store
- Upload IPAs to Apple TestFlight
- Publish Windows/macOS/Linux packages
- Deploy web build to CDN/hosting
- Announce releases to users

---

## Troubleshooting

### Version Mismatch Error

**Error**: `Configuration validation failed: Editions mismatch between files`

**Solution**: Ensure all three config files have same editions:

```bash
# Check editions.json
cat config/editions.json | python -m json.tool

# Check version_config.json
cat config/version_config.json | python -m json.tool

# Check features.json
cat config/features.json | python -m json.tool

# Add missing editions to version_config.json if needed
```

### Build Generator Not Finding Config

**Error**: `version_config.json not found`

**Solution**: Verify you're running from project root:

```bash
pwd
# Should output: /path/to/Star Trails

# Run generator with explicit paths
python build/build_version_generator.py \
  --edition PUB \
  --editions-config "$(pwd)/config/editions.json" \
  --version-config "$(pwd)/config/version_config.json"
```

### Flutter Build Fails on Version Variables

**Error**: `Undefined variable: APP_EDITION`

**Solution**: Ensure environment variables are exported:

```bash
# Verify variables are set
echo $EDITION
echo $FULL_VERSION

# If empty, regenerate and re-export
export $(python build/edition_build_generator.py --use-manifest)

# Verify again
echo $EDITION
```

### Auto-Version Hook Not Triggering

**Error**: Version not bumped on commit

**Solution**: Re-setup hooks:

```bash
python scripts/setup_auto_versioning.py

# Verify hook is installed
ls -la .git/hooks/pre-commit

# Test manually
python scripts/bump_version.py patch
```

### Platform Build Takes Too Long

**Solution**: Use incremental builds:

```bash
# Flutter incremental build (much faster)
flutter build android --incremental

# Or skip rebuild for testing
flutter build android --fast-start
```

### Release APK Signing Issues

**Create keystore** (one-time):

```bash
keytool -genkey -v -keystore ~/.android/release-key.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release-key
```

**Update Flutter config** `android/key.properties`:

```properties
storeFile=/path/to/.android/release-key.keystore
storePassword=your-password
keyAlias=release-key
keyPassword=your-password
```

---

## CI/CD Integration Example (GitHub Actions)

Create `.github/workflows/build.yml`:

```yaml
name: Build All Editions

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            platform: android
          - os: ubuntu-latest
            platform: linux
          - os: ubuntu-latest
            platform: web
          - os: macos-latest
            platform: ios
          - os: macos-latest
            platform: macos
          - os: windows-latest
            platform: windows
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'latest'
      
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Generate version
        run: |
          python build/build_version_generator.py \
            --use-manifest \
            --validate-config \
            --set-github-output
      
      - name: Build ${{ matrix.platform }}
        run: |
          export $(python build/edition_build_generator.py --use-manifest)
          flutter build ${{ matrix.platform }} \
            --release \
            --build-name "${{ env.FLUTTER_BUILD_NAME }}" \
            --build-number "${{ env.FLUTTER_BUILD_NUMBER }}" \
            --dart-define APP_EDITION="${{ env.EDITION }}" \
            --dart-define FULL_VERSION="${{ env.FULL_VERSION }}"
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.platform }}-${{ env.FULL_VERSION }}
          path: build/${{ matrix.platform }}/**/*
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Check current edition | `python core/version_manager/edition_detector.py` |
| List all editions | `cat config/editions.json \| python -m json.tool` |
| View versions | `cat config/version_config.json \| python -m json.tool` |
| Bump patch (all) | `python scripts/bump_version.py patch` |
| Bump minor (all) | `python scripts/bump_version.py minor` |
| Bump major (all) | `python scripts/bump_version.py major` |
| Validate config | `python -c "from core.version_manager import ConfigValidator; ConfigValidator.print_validation_report()"` |
| Generate version | `python build/edition_build_generator.py --use-manifest` |
| Build Android | `flutter build apk --release` |
| Build iOS | `flutter build ipa --release` |
| Build Windows | `flutter build windows --release` |
| Build macOS | `flutter build macos --release` |
| Build Linux | `flutter build linux --release` |
| Build Web | `flutter build web --release` |
| Run tests | `flutter test` |
| Run analysis | `flutter analyze` |

---

## Support

For detailed technical information, see:
- [VERSIONING_SYSTEM_SPECIFICATION.md](VERSIONING_SYSTEM_SPECIFICATION.md) - Complete technical reference
- [README.md](README.md) - Project overview

