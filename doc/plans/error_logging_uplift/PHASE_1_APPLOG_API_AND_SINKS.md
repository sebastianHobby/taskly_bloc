# Error + Logging Uplift — Phase 1: AppLog API & Sinks

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

Strengthen `AppLog` so it can serve as the single default logging entrypoint while keeping Talker as the sink.

## Scope

- Expand/normalize `AppLog` API (if needed).
- Add central gating/throttling defaults.
- Align Talker fail-fast policy with `AppLog` categories.

## Files likely to touch

- `lib/core/logging/app_log.dart`
- `lib/core/logging/talker_service.dart`
- (optional) `lib/core/logging/*` (new helper types if absolutely necessary)

## Tasks

### 1.1 Normalize `AppLog` surface area

Evaluate whether `AppLog` should provide these methods (existing + additions):

- `routine(category, message, {error, stackTrace})` (already)
- `routineThrottled(key, interval, category, message, {error, stackTrace})` (already)
- `info(category, message)` (already)
- `warn(category, message)` (already)
- `error(category, message)` (already)
- `handle(category, message, error, [stackTrace])` (already)

Potential additions (only if they reduce direct `talker.*` usage):

- `debug(category, message)` as an alias to `routine` OR as a separately-gated low-volume debug call.
- `event(category, message, {Map<String, Object?> fields})` if you want structured-ish logs without adding a logging vendor.

Acceptance criteria:
- Call sites that currently use `talker.debug(...)` for routine flow can switch to `AppLog.routine(...)` without losing route context.

### 1.2 Add environment-controlled verbosity

Add one or more `--dart-define` switches for controlling noise without code changes, for example:

- `LOG_VERBOSE=true|false` (default false in release)
- `LOG_PERSIST_INFO=true|false` (if you later persist info-level logs)

Implementation notes:
- Keep `AppLog.routine` suppressed by default in release builds.
- Ensure `AppLog.handle/error/warn` remain available in release (but still avoid spamming).

Acceptance criteria:
- In debug: routine logs are visible.
- In release: routine logs are suppressed unless explicitly enabled.

### 1.3 Align fail-fast with categories (not message prefixes)

Current: `TalkerFailFastPolicy` triggers based on message prefixes (brittle).

Refactor direction:
- Prefer fail-fast rules based on:
  - `category` prefix (e.g., `data.*` and `domain.*`)
  - exception type allow/deny list (already partially exists)

Implementation approach:
- Introduce an internal convention so `AppLog.handle` prefixes messages in a parseable way, e.g.:
  - `[$category] ...` already exists.
- Update fail-fast to check for `message.startsWith('[data.')` and/or `message.startsWith('[domain.')`.
- Keep allowlist for expected exceptions (AuthException, PostgrestException, SocketException, TimeoutException, RepositoryValidationException).

Acceptance criteria:
- A data-layer exception logged through `AppLog.handle('data.xxx', ...)` can trigger fail-fast in debug when configured.

### 1.4 Decide what gets persisted to file

You currently have a debug file observer in Talker.

Decisions to document:
- Persist only `warn/error/handle` by default (recommended).
- Do not persist `routine` by default.
- For perf: persist only slow-path warnings (`[Perf] ... slow ...`). Detailed perf stays `developer.log`.

Acceptance criteria:
- On-device persistent logs stay high-signal.

## AI instructions (required)

- Review `doc/architecture/*` before implementing.
- Run `flutter analyze` and fix all errors/warnings introduced/discovered.
- Do not run tests in this phase.

## Completion checklist

- `AppLog` API is sufficient for most call sites.
- Central verbosity switches exist (if needed) and are documented.
- Fail-fast behavior matches category usage.
- `flutter analyze` clean.
