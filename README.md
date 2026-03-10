# Star Trails

© 2026 Ubertas Lab, LLC. All rights reserved.

Star Trails™ is proprietary software.
No part of this software may be reproduced, stored, or transmitted in any form without written permission.

---

Offline educational trading game built with Flutter.

## How to run

Prerequisites:
- Flutter SDK (Dart included)

Commands:
```bash
flutter pub get
flutter run
```

Run tests:
```bash
flutter test
```

## How to build release

Examples:
```bash
flutter build apk --release
flutter build web --release
flutter build windows --release
```

Use the matching `flutter build <platform> --release` command for your target.

## High-level architecture

- `lib/main.dart`: app entry point and root app widget.
- `lib/providers/`: app state and gameplay orchestration (`GameProvider`).
- `lib/models/`: immutable data models for game and teacher dashboard data.
- `lib/services/`: local persistence and teacher dashboard storage.
- `lib/screens/`: UI screens and player flow.
- `lib/utils/`: shared constants, theme, painters, routing, and helpers.

The app is designed to run fully offline using local storage only.

## Cross-platform edition versioning

This repository includes an edition-aware versioning module for consistent release metadata across Android, iOS, Windows, macOS, Linux, and Web.

- Core module: `core/version_manager/`
- Build generators: `build/build_version_generator.py`, `build/edition_build_generator.py`
- Config files: `config/editions.json`, `config/version_config.json`, `config/version_history.json`, `config/features.json`
- Technical reference: `VERSIONING_SYSTEM_SPECIFICATION.md`

Quick version bump:

```bash
python scripts/bump_version.py patch
```

Run versioning tests:

```bash
python -m unittest tests/version_tests.py
```
