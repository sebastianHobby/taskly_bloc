# Error + Logging Uplift — Phase 3: Error Model & Boundaries

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Make error handling architecture consistent across layers by introducing a small, shared error model for UI and clarifying rules for throwing vs returning failures.

## Scope

- Define a single UI-facing error shape (e.g., `AppError` / `UiError`).
- Standardize “stream error policy” and “rethrow policy” by build mode.
- Improve typed repository exceptions usage.

## Files likely to touch

- `lib/presentation/shared/...` (shared state/error types)
- `lib/data/repositories/repository_exceptions.dart`
- Selected blocs that currently `rethrow` after logging

## Tasks

### 3.1 Define `AppError` (UI-facing)

Create a small immutable type with:
- `code` (string/enum)
- `message` (user-safe)
- `debugMessage` (optional; only shown in debug)
- `severity` (info/warn/error)
- `isRetryable` (bool)
- `cause` (Object?) + `stackTrace` (StackTrace?) for diagnostics

Guidelines:
- UI states should carry `AppError` instead of raw `Object error`.
- Always log the underlying exception with `AppLog.handle` at the boundary.

Acceptance criteria:
- At least one shared bloc mixin or base state adopts `AppError`.

### 3.2 Layer rules (document + enforce incrementally)

- Data layer:
  - Throw typed exceptions (`RepositoryException` variants) for failures.
  - Re-throw after logging only if adding meaningful context.
- Domain layer:
  - Prefer returning `Result`/nullable for expected “no data” cases; throw only for invariants.
- Presentation layer:
  - Catch exceptions, log once, convert to `AppError` and emit error state.
  - Avoid `rethrow` in release builds.

Acceptance criteria:
- A small number of representative flows are updated to follow the rules.

### 3.3 Stream error policy

Define a consistent approach:
- In release: a stream error should not crash the app; emit error state and keep UI usable.
- In debug: optionally fail-fast for high-signal categories (data/domain invariants).

Audit targets:
- Blocs that wrap `emit.forEach` with `try/catch` and `rethrow`.

Acceptance criteria:
- Stream errors do not unintentionally bubble to zone handler in release.

## AI instructions (required)

- Review `doc/architecture/*` before implementing.
- Run `flutter analyze` and fix all errors/warnings introduced/discovered.
- Do not run tests in this phase.

## Completion checklist

- Shared `AppError` exists and is used by at least one shared flow.
- Rethrow policy documented and partially applied.
- `flutter analyze` clean.
