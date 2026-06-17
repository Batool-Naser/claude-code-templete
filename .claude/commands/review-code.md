Review the file or files specified by `$ARGUMENTS` against this project's standards.

Check every item below and report findings grouped by category. Mark each PASS or FAIL with the file path and line number where relevant.

**Data flow** — enforced direction: `Screen → Notifier → Repository → Provider → API/Database`
- `screen/` files contain no API calls, no repository calls, no business logic.
- `application/notifier/` files call only `repository/` — never `provider/` directly.
- `repository/` files call only `provider/` — never `application/` or `screen/`.
- `provider/` files contain no business logic and no UI state.

**Widget size**
- No file in `screen/` or `widgets/` exceeds 150 lines.
- No `build` method exceeds 100 lines.

**State**
- Every state class lives in `application/state/` and uses Freezed (`@freezed`).
- State has `initial`, `loading`, `data`, and `error` variants.
- No `setState` or `ChangeNotifier` usage anywhere.

**Riverpod**
- All provider variables end with `Provider`.
- Notifiers are `Notifier` or `AsyncNotifier` subclasses.

**Models**
- Feature-specific models live in `model/` with Freezed and `fromJson`/`toJson`.
- Models used by 2+ features are in `core/shared_models/`.

**Repository**
- Abstract interface and `_impl` class both exist in `repository/`.
- The impl calls only `provider/`.

**Naming**
- File names are `snake_case`.
- Class names are `PascalCase`.
- Screens: `<name>_screen.dart`, notifiers: `<name>_notifier.dart`, state: `<name>_state.dart`.

**Reusability**
- Widgets used by more than one screen are in the feature's `widgets/` folder.
- No duplicated widget code across screens.

End the review with a prioritised list of required fixes (FAIL items) followed by optional improvements.
