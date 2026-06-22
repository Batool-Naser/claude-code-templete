---
name: project-architecture
description: Core architecture conventions for this Flutter todo_app project — feature structure, state management, navigation, naming rules
metadata:
  type: project
---

Feature-first Clean Architecture. Data flow: Screen → Notifier → Repository → Provider → API.

Feature folder layout under `lib/features/<name>/`:
- `screen/` — ConsumerWidget only, no business logic
- `widgets/` — pure presentation, receive data via params
- `application/notifier/` — Notifier/AsyncNotifier subclasses
- `application/state/` — Freezed sealed state unions
- `repository/` — abstract interface + `_impl.dart`
- `provider/` — REST/local access stubs, no business logic
- `model/` — Freezed models with fromJson/toJson

State management: **flutter_riverpod ^2.6.1** (manual `NotifierProvider`, not generator macros — codegen packages are in dev_deps but not used yet).

Navigation: **GoRouter** (referenced in CLAUDE.md but not yet installed; stubs in place).

Models: **Freezed + json_annotation** — requires `dart run build_runner build --delete-conflicting-outputs` after any `@freezed` change.

Key rules:
- Widget files max 150 lines; build methods max 100 lines.
- All Riverpod provider variables end with `Provider`.
- State is immutable (Freezed sealed unions).
- Notifiers call only repositories — never providers directly.

**Why:** Established in CLAUDE.md and enforced throughout first feature implementation.
**How to apply:** Follow this structure for every new feature. Check CLAUDE.md for the authoritative reference.
