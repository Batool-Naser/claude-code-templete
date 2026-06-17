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

# Codegen (Freezed + Riverpod)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

This project is a Flutter application targeting macOS, iOS, Android, web, Linux, and Windows.

- **Entry point**: `lib/main.dart` — mounts `MainApp`, a `StatelessWidget` wrapping a `MaterialApp`.
- **SDK constraint**: Dart `^3.12.2`, using Material Design (`uses-material-design: true`).
- **Linting**: `flutter_lints` via `analysis_options.yaml`.

All app code lives under `lib/`. Platform-specific folders (`android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/`) contain generated runner shells and should rarely need manual edits.

## Flutter Project Standards

### Stack
- **State management**: Riverpod
- **HTTP**: Dio + Retrofit
- **Models**: Freezed
- **Navigation**: GoRouter

### Project Structure

```
lib/
├── core/
│   ├── network/          # Dio client, interceptors, api_constants
│   ├── services/         # App-wide services (auth, analytics, notifications)
│   ├── shared_models/    # Models used by 2+ features
│   ├── constants/        # URLs, keys, default values
│   ├── extensions/       # Dart extension methods
│   └── utils/            # Pure stateless helper functions
│
├── features/
│   ├── authentication/
│   ├── home/
│   ├── profile/
│   └── settings/
│
└── main.dart
```

### Feature Structure

```
features/
└── feature_name/
    ├── screen/           # Screens and pages
    ├── widgets/          # Reusable widgets for this feature only
    ├── application/
    │   ├── notifier/     # Riverpod notifiers — handle actions, call repositories
    │   └── state/        # Immutable UI state classes
    ├── repository/       # Abstract interface + impl; single source of truth
    ├── provider/         # Raw data access: REST, GraphQL, local DB, SharedPrefs
    └── model/            # Feature-specific request/response/domain models
```

### Layer Responsibilities

| Folder | Responsibility |
|---|---|
| `screen/` | Build UI, watch providers, trigger actions. No API calls or business logic. |
| `widgets/` | Display UI via parameters. No business logic or API calls. |
| `application/state/` | Immutable state classes (loading, success, error, form). |
| `application/notifier/` | Handle user actions, call repositories, update state. |
| `repository/` | Coordinate data sources, convert provider results to models. |
| `provider/` | REST / GraphQL / DB / storage access only. No business logic. |
| `model/` | Feature-specific models. Move to `core/shared_models/` if used by 2+ features. |

### Data Flow

Request:
```
Screen → Notifier → Repository → Provider → API / Database
```

Response:
```
API / Database → Provider → Repository → Notifier → State → Screen
```

### Architecture Rules

- Screens never call APIs or repositories directly.
- State is immutable; only notifiers update it.
- Notifiers communicate only with repositories (never directly with providers).
- Repositories combine data sources and hide implementation details from notifiers.
- Providers access external systems only — no business logic.
- Feature-specific models stay in `model/`; shared models go in `core/shared_models/`.
- Dependencies flow downward only: Screen → Notifier → Repository → Provider.

### UI Rules

- Screen files contain layout only — no business logic.
- Widgets should be small and reusable; receive data through parameters.
- No widget file larger than 150 lines; no `build` method larger than 100 lines.

### Naming

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case` | `profile_screen.dart` |
| Classes | `PascalCase` | `ProfileScreen` |
| Screens | `<name>_screen.dart` | `login_screen.dart` |
| Widgets | `<name>.dart` | `user_avatar.dart` |
| State | `<name>_state.dart` | `profile_state.dart` |
| Notifier | `<name>_notifier.dart` | `profile_notifier.dart` |
| Repository | `<name>_repository.dart` / `<name>_repository_impl.dart` | — |
| Provider | `<name>_api_provider.dart` / `<name>_local_provider.dart` | — |
| Model | `<name>_model.dart` | `profile_model.dart` |
| Riverpod vars | ends with `Provider` | `profileNotifierProvider` |

## Slash Commands

Custom commands live in `.claude/commands/`. Invoke them with `/project:<name>`.

| Command | Agent | What it does |
|---|---|---|
| `/project:create-feature <name>` | `@flutter-architect` | Scaffolds all feature folders and placeholder files. |
| `/project:create-screen <feature/screen>` | `@flutter-screen-generator` | Asks for screen name + requirements, then generates state, notifier, and screen files. |
| `/project:review-code <path>` | — | Audits files against project standards and outputs a prioritised list of failures. |
