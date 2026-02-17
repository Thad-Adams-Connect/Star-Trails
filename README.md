# Star Trails

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
