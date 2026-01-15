# Error + Logging Uplift — Phase 2: Call-site Migration & Noise Reduction

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Migrate the codebase toward AppLog-first usage and reduce noisy logs while increasing signal where errors are currently silent.

## Scope

- Replace direct `talker.*` usage with `AppLog.*` where appropriate.
- Add missing logging in shared helpers (especially list flows).
- Make high-volume logs throttled by default.

## Files likely to touch (examples)

- `lib/presentation/shared/mixins/list_bloc_mixin.dart` (critical)
- `lib/presentation/shared/mixins/detail_bloc_mixin.dart` (optional alignment)
- Feature blocs/services that currently call `talker.handle` directly
- High-volume stream emitters in repositories (ensure throttling)

## Migration rules

### 2.1 Use `AppLog` in most app code

Replace:
- `talker.debug(...)` → `AppLog.routine(...)`
- `talker.info(...)` → `AppLog.info(...)`
- `talker.warning(...)` → `AppLog.warn(...)`
- `talker.error(...)` → `AppLog.error(...)`
- `talker.handle(e, st, msg)` → `AppLog.handle(category, msg, e, st)`

Exceptions (allowed direct Talker usage):
- `bootstrap.dart` zone/framework error hooks
- Places that must pass `Talker` to external widgets/APIs (TalkerScreen, TalkerRouteObserver)

Acceptance criteria:
- New code guidelines: “default to `AppLog`”.

### 2.2 Fix silent errors in list flows

Problem:
- `ListBlocMixin.executeDelete/executeToggle` catches exceptions and emits error state but does not log.

Fix:
- Add `AppLog.handle('ui.<bloc_or_feature>', ...)` or require a `logger` similar to DetailBlocMixin.

Preferred minimal change:
- Import `AppLog` and log within `ListBlocMixin` with a generic category like `ui.list_bloc`.
- If you need per-feature categories, require a `String get logCategory;` getter on the mixin.

Acceptance criteria:
- Any caught exception in list flows is logged with stack trace.

### 2.3 Reduce high-volume stream logs

Rules:
- Any log inside a `.map` on a stream that fires frequently must use `routineThrottled`.
- Avoid per-item logs; log counts/summaries.

Targets:
- Repository watchers and shared streams
- Scheduled screen query details (`perf.scheduled.query`) — ensure detailed lines are debug-only or throttle.

Acceptance criteria:
- No “every emission” debug log without throttling.

### 2.4 Standardize error messages for UI

Rule:
- Avoid emitting raw `error.toString()` directly into UI state as the primary message.
- Prefer a user-safe message with an internal logged exception.

Acceptance criteria:
- BLoC states expose consistent, user-safe error messages.

## Suggested mechanical approach

- Start with grep for `talker.` and migrate in descending frequency (most-used files first).
- For each migrated file:
  - pick a category prefix and keep it consistent
  - use throttling for hot paths

## AI instructions (required)

- Review `doc/architecture/*` before implementing.
- Run `flutter analyze` and fix all errors/warnings introduced/discovered.
- Do not run tests in this phase.

## Completion checklist

- `ListBlocMixin` logs exceptions.
- Majority of new/edited call sites use `AppLog`.
- High-volume logging is throttled.
- `flutter analyze` clean.
