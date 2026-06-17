Use @flutter-architect

Create a complete feature named `$ARGUMENTS`.

Generate all folders and placeholder implementations following this exact structure:

```
lib/features/<feature>/
├── screen/
├── widgets/
├── application/
│   ├── notifier/
│   └── state/
├── repository/
├── provider/
└── model/
```

For each folder generate the following placeholder files:

**screen/**
- `<feature>_screen.dart` — `ConsumerWidget`. Watches the notifier provider, handles every state variant, delegates layout to `widgets/`. No business logic.

**widgets/**
- `<feature>_<section>_widget.dart` — Stateless widget(s) that receive data through parameters. No business logic or API calls.

**application/state/**
- `<feature>_state.dart` — Freezed sealed class with `initial`, `loading`, `data(<Model>)`, and `error(String)` variants. Include the `part` directive.

**application/notifier/**
- `<feature>_notifier.dart` — `AsyncNotifier` subclass. Handles user actions, calls the repository, and updates state. Provider variable ends with `Provider`. Never calls providers directly.

**repository/**
- `<feature>_repository.dart` — Abstract interface with one stub method.
- `<feature>_repository_impl.dart` — Concrete implementation that calls the provider and converts results to models.

**provider/**
- `<feature>_api_provider.dart` — Retrofit `@RestApi` abstract class with one stub endpoint and a `TODO: set base URL` comment.
- `<feature>_local_provider.dart` — Stub for local storage access (SharedPreferences / secure storage).

**model/**
- `<feature>_model.dart` — Freezed model with `fromJson`/`toJson`. Include the `part` directive.

If a model is (or will be) used by more than one feature, place it in `lib/core/shared_models/` instead.

After generating all files, print:

**Follow-up checklist**
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` (Freezed + Riverpod codegen).
- [ ] Register the repository impl in your DI/provider overrides.
- [ ] Add the screen route to the root `GoRouter`.
- [ ] Replace stub endpoints and base URL in `provider/<feature>_api_provider.dart`.
- [ ] Move `<feature>_model.dart` to `core/shared_models/` if other features need it.
