# Error + Logging Uplift — Phase 5: Docs, Guidelines, and Wrap-up

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Document conventions so new code remains consistent, and define done criteria for the uplift.

## Scope

- Add/extend documentation for logging and error handling.
- Add a brief migration guide for contributors.

## Suggested documentation updates

- Add a new doc (or section) describing:
  - default: use `AppLog`
  - category taxonomy
  - when to use `developer.log` (perf)
  - what gets persisted
  - PII rules and masking helpers
  - error boundary rules by layer

Possible locations:
- `doc/architecture/README.md` (add a short “Diagnostics” section)
- or a dedicated `doc/architecture/DIAGNOSTICS_LOGGING_ERROR_HANDLING.md`

## Done criteria (practical)

- 80/20:
  - Hot paths and shared abstractions use `AppLog`.
  - Most direct `talker.*` calls remain only where required.
- Silent errors fixed:
  - Shared mixins and common patterns log exceptions.
- Release safety:
  - routine logs suppressed
  - no PII in persisted logs
- Developer experience:
  - easy to find logs in DevTools and Talker
  - categories consistent

## AI instructions (required)

- Review `doc/architecture/*` before implementing.
- Run `flutter analyze` and fix all errors/warnings introduced/discovered.
- Do not run tests in this phase unless this is the final phase; if final, run `flutter_test_report` once.

## Completion checklist

- Docs updated and consistent with implementation.
- Plan folder ready to move to `doc/plans/completed/error_logging_uplift/` once implemented.

