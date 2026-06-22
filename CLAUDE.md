# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or simulator
flutter run
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

# Codegen — run after adding/changing Freezed models or Riverpod annotations
dart run build_runner build --delete-conflicting-outputs
```

## Current State

`lib/main.dart` is a bare-bones `StatelessWidget` with a "Hello World" scaffold. The dependencies in `pubspec.yaml` are currently just `flutter` and `flutter_lints`. The architecture below describes the **intended** stack — add packages before scaffolding features:

```yaml
dependencies:
  flutter_riverpod: ...
  riverpod_annotation: ...
  go_router: ...
  dio: ...
  retrofit: ...
  freezed_annotation: ...
  json_annotation: ...

dev_dependencies:
  build_runner: ...
  freezed: ...
  retrofit_generator: ...
  json_serializable: ...
  riverpod_generator: ...
```

## Architecture

Feature-first Clean Architecture. All app code lives under `lib/`.

```
lib/
├── core/
│   ├── network/          # Dio client, interceptors, api_constants
│   ├── services/         # App-wide services (auth, analytics, notifications)
│   ├── shared_models/    # Models used by 2+ features
│   ├── constants/        # URLs, keys, default values
│   ├── extensions/       # Dart extension methods
│   └── utils/            # Pure stateless helper functions
├── features/
│   └── <feature>/
│       ├── screen/                    # ConsumerWidgets — layout only
│       ├── widgets/                   # Feature-scoped reusable widgets
│       ├── application/
│       │   ├── notifier/              # AsyncNotifier subclasses
│       │   └── state/                 # Freezed sealed state classes
│       ├── repository/                # Abstract interface + _impl
│       ├── provider/                  # REST / local storage access only
│       └── model/                     # Freezed models with fromJson/toJson
└── main.dart
```

### Data Flow

```
Screen → Notifier → Repository → Provider → API / Database
```

### Hard Rules

- Screens never call repositories or providers directly.
- Notifiers call only repositories — never providers.
- Repositories call only providers — no business logic.
- Providers access external systems only — no business logic.
- State is immutable (Freezed); only notifiers update it.
- Dependencies flow one direction: Screen → Notifier → Repository → Provider.
- Feature models stay in `model/`; move to `core/shared_models/` when used by 2+ features.
- No widget file > 150 lines; no `build` method > 100 lines.

### Naming

| Type | Convention |
|---|---|
| Files | `snake_case` |
| Classes | `PascalCase` |
| Screens | `<name>_screen.dart` |
| State | `<name>_state.dart` |
| Notifier | `<name>_notifier.dart` |
| Repository | `<name>_repository.dart` / `<name>_repository_impl.dart` |
| Provider | `<name>_api_provider.dart` / `<name>_local_provider.dart` |
| Model | `<name>_model.dart` |
| Riverpod vars | ends with `Provider` |

## Slash Commands

Custom commands live in `.claude/commands/`. Invoke with `/project:<name>`.

| Command | What it does |
|---|---|
| `/project:create-feature <name>` | Scaffolds all feature folders and placeholder files (state, notifier, screen, repository, provider, model). |
| `/project:create-screen <feature/screen>` | Prompts for screen name + requirements, then generates state, notifier, widgets, and screen. |
| `/project:review-code <path>` | Audits files against architecture rules and outputs a prioritised PASS/FAIL list. |
