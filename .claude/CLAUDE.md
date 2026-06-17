# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or simulator
flutter run

# Run on a specific platform
flutter run -d macos
flutter run -d chrome

# Build
flutter build macos
flutter build apk
flutter build web

# Tests
flutter test                        # all tests
flutter test test/widget_test.dart  # single file

# Lint / analyze
flutter analyze

# Format
dart format lib/
```

## Architecture

This project is a Flutter application targeting macOS, iOS, Android, web, Linux, and Windows.

- **Entry point**: `lib/main.dart` — mounts `MainApp`, a `StatelessWidget` wrapping a `MaterialApp`.
- **SDK constraint**: Dart `^3.12.2`, using Material Design (`uses-material-design: true`).
- **Linting**: `flutter_lints` via `analysis_options.yaml`.

All app code lives under `lib/`. Platform-specific folders (`android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/`) contain generated runner shells and should rarely need manual edits.

## Flutter Project Standards

### Architecture
- Feature-first with Clean Architecture.
- **State management**: Riverpod.
- **HTTP**: Dio + Retrofit.
- **Models**: Freezed.
- **Navigation**: GoRouter.

### Folder Structure

```
lib/
└── features/
    └── feature_name/
        ├── presentation/
        │   ├── screens/
        │   ├── widgets/
        │   ├── providers/
        │   └── controllers/
        ├── domain/
        └── data/
```

### UI Rules
- Screen files contain layout only — no business logic.
- Reusable widgets go in the `widgets/` folder.
- No widget file larger than 150 lines; no `build` method larger than 100 lines.

### Naming
- `snake_case` file names.
- `PascalCase` class names.
- Riverpod provider variables end with `Provider`.
