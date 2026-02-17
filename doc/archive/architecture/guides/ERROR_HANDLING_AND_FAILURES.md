# Error Handling and Failures

> Audience: developers
>
> Scope: descriptive guidance for how errors flow across layers and how the
> `AppFailure` taxonomy is used. Normative rules live in
> [../INVARIANTS.md](../INVARIANTS.md#8-error-handling-across-boundaries).

## 1) The shape of failures (domain taxonomy)

Taskly standardizes expected failures in `taskly_domain`:

- `AppFailure` (sealed) in `packages/taskly_domain/lib/src/errors/app_failure.dart`
- `AppFailureKind`: `auth`, `unauthorized`, `forbidden`, `validation`,
  `notFound`, `network`, `timeout`, `rateLimited`, `storage`, `unknown`

`AppFailure.uiMessage()` provides a safe default string for screens that need
a fallback. Presentation can layer localization or richer UX on top.

## 2) Error flow across layers (typical path)

```text
Data exception -> AppFailureMapper / FailureGuard -> AppFailure
Domain returns typed failures -> Presentation maps to state
UI renders a safe message or tailored experience
```

### Data layer mapping

Data implementations typically use `FailureGuard.run(...)`:

```dart
return FailureGuard.run(
  () async {
    // actual data operation
  },
  area: 'data.tasks',
  opName: 'create',
  context: context,
);
```

`FailureGuard` uses `AppFailureMapper` so low-level exceptions become typed
`AppFailure` values that the presentation layer can handle deterministically.

### Presentation usage

Presentation code (BLoCs / query services) typically:

- catches `AppFailure`,
- maps it to a user-visible state, and
- renders a message via `uiMessage()` when no localized string exists.

Unknown or unexpected failures can still be reported through
`AppFailure.reportAsUnexpected`.

## 3) Extending the taxonomy

When a new exception type appears in Data:

- add the mapping in `AppFailureMapper`,
- add or update tests in `packages/taskly_data/test/unit/errors/`,
- only add new `AppFailureKind` variants when the UI needs a stable, reusable
  category.

## 4) Seed tests (templates)

Use these seed tests as copy/paste starting points:

- `packages/taskly_data/test/unit/errors/failure_guard_seed_test.dart`
- `packages/taskly_data/test/unit/errors/app_failure_mapper_test.dart`
