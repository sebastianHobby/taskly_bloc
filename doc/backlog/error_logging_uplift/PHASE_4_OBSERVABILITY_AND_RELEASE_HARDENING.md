# Error + Logging Uplift — Phase 4: Observability & Release Hardening

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Harden production diagnostics while controlling log volume and avoiding PII.

## Scope

- Decide whether to add remote crash reporting (Sentry/Crashlytics) or keep local-only.
- Ensure release builds do not persist noisy logs.
- Improve correlation identifiers (session/boot id).

## Tasks

### 4.1 Optional: Remote crash reporting integration

Choose one:
- `sentry_flutter` (multi-platform + optional performance tracing)
- `firebase_crashlytics` (standard mobile pipeline)

Integration rules:
- Forward only `AppLog.error` + `AppLog.handle` (and selectively throttled `warn`).
- Do NOT forward `routine` logs.
- Redact/mask PII (emails already masked in `AppLog`).

Acceptance criteria:
- Uncaught errors captured remotely.
- A small set of caught exceptions (high value) captured with context.

### 4.2 Boot/session correlation

Add a simple `bootId` / `sessionId` to log formatting:
- generated once in bootstrap
- included by `AppLog` formatter

Acceptance criteria:
- Exported logs can be grouped by run.

### 4.3 Release log volume control

- Ensure `routine` logs are suppressed in release.
- Ensure persisted logs (if any) are limited to warn/error/handle.

Acceptance criteria:
- Release build does not generate large local log files.

## AI instructions (required)

- Review `doc/architecture/*` before implementing.
- Run `flutter analyze` and fix all errors/warnings introduced/discovered.
- Run tests once at the end of the final implementation using VS Code task `flutter_test_report`.

## Completion checklist

- Remote crash reporting decision implemented or explicitly documented as deferred.
- Correlation IDs are present.
- Release log volume is controlled.
- `flutter analyze` clean.
- Tests executed once at end (recorded).

