# Error + Logging Uplift — Phase 0: Context & Principles

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Establish a consistent, AppLog-first logging approach (Option A) and tighten error-handling conventions across layers (presentation/domain/data) without destabilizing production behavior.

This plan is written to be directly executable by an AI implementing in this repo.

## Non-goals

- Replacing Talker as the logging sink (Talker stays).
- Introducing a full DI-injected logger (Option C) in this uplift.
- Adding a new architectural pattern without explicit confirmation.
- Massive sweeping rename/reformat across the entire repo in one pass.

## Current repo baseline (observed)

- Global error capture is centralized in `lib/bootstrap.dart`:
  - `runZonedGuarded`
  - `FlutterError.onError`
  - `PlatformDispatcher.instance.onError`
  - `_BootstrapFailureApp` fallback UI
- Logging stack:
  - `lib/core/logging/talker_service.dart` defines `TasklyTalker` with an optional debug fail-fast policy.
  - `lib/core/logging/app_log.dart` is a facade that already provides categories + route context.
  - Many call sites still use `talker.*` directly.
- Observability/perf:
  - `dart:developer` logs exist for perf channels (`perf.*`) and scheduled screen diagnostics.

## “Option A” North Star

- All non-performance logging should flow through `AppLog` by default.
- Talker remains the sink (console + in-app viewer + debug file observer).
- `dart:developer` is reserved for DevTools-only streams (perf traces, scheduled deep dives).

## Key problems to solve

1. **Mixed entrypoints**: `AppLog.*` vs `talker.*` direct usage.
2. **Silent errors**: some helper/mixin patterns emit error states without logging.
3. **Fail-fast mismatch**: fail-fast policy triggers on message prefixes that don’t match most `AppLog` formatting.
4. **Unclear layer responsibilities**: inconsistent rethrow vs swallow vs degrade.

## Guiding principles

- **Prefer category-based consistency over bespoke messages.**
- **Log at the boundary**:
  - Data layer logs when transforming external/runtime failures into domain failures.
  - Presentation logs when converting failures into user-visible states.
- **Don’t log twice** for the same exception across adjacent layers unless adding distinct context.
- **Avoid PII**: log only masked emails/IDs; do not log raw tokens, full SQL rows, or entire objects.
- **Make high-volume logs throttled** by default.

## Category taxonomy (proposed)

Keep it small and stable:

- `ui.*` – widgets/screens, user actions
- `navigation.*` – route transitions, deep links
- `domain.*` – business logic, orchestration services
- `data.*` – repositories, persistence
- `sync.*` – PowerSync, Supabase sync/status
- `perf.*` – perf warnings that you *persist* (detailed perf stays in DevTools)
- `security.*` – auth/session-sensitive events (never include secrets)

### Severity rules (proposed)

- `routine`: very high volume, debug-only, throttled
- `info`: meaningful milestones (auth state changes, bootstrap milestones)
- `warn`: degraded behavior, slow operations, retries, unexpected-but-recovered
- `error/handle`: exceptions, invariants, user-impacting failures

## AI instructions (required)

- Review `doc/architecture/*` before implementing any phase and keep docs updated if architecture changes.
- Run `flutter analyze` during the phase; fix any errors/warnings introduced (or discovered) by the end of the phase.
- Do **not** run tests repeatedly while iterating. Run tests **once** at the end of the final implementation phase using the `flutter_test_record` task.

## Exit criteria for the overall plan

- Logging uses `AppLog` as the default entrypoint across the majority of the codebase.
- Error handling is consistent by layer and avoids silent failures.
- High-volume logs are throttled and/or debug-only.
- Debug fail-fast behavior is aligned with real category usage.
- `flutter analyze` is clean.
- Tests are run once at the end (recorded).
