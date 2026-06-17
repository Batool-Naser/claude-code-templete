Use @flutter-screen-generator

Ask for:
- Screen name (e.g. `profile/edit` → feature `profile`, screen `EditProfileScreen`)
- Requirements (what the screen shows, what actions it supports, what data it needs)

Wait for both answers before generating anything.

Generate in this order:

**1. Folder structure** — print exact file paths before writing anything.

```
lib/features/<feature>/
├── screen/          <screen>_screen.dart
├── widgets/         <screen>_<section>_widget.dart  (as many as needed)
└── application/
    ├── state/       <screen>_state.dart
    └── notifier/    <screen>_notifier.dart
```

**2. State** (`application/state/<screen>_state.dart`)
- Freezed sealed class with `initial`, `loading`, `data(...)`, and `error(String)` variants.
- Include the `part` directive for codegen.

**3. Notifier** (`application/notifier/<screen>_notifier.dart`)
- `AsyncNotifier` subclass that manages state.
- Provider variable ends with `Provider`.
- Calls into `repository/` only — never directly into `provider/`.
- One method per user action derived from the requirements.

**4. Widgets** (`widgets/`)
- Extract each distinct UI section into its own file when the `build` method would exceed 100 lines or the section is reusable.
- Each widget file stays under 150 lines.
- Widgets receive data through parameters — no `ref` inside widgets unless required.

**5. Screen** (`screen/<screen>_screen.dart`)
- `ConsumerWidget` only.
- Layout and `ref.watch` calls only — zero business logic.
- `build` method under 100 lines.
- Handles every state variant from the state class.
- Composes widgets from `widgets/`.
