# Screen Data Pipeline Guide

> Audience: developers + architects
>
> Scope: a consistent app-wide pattern for screen data loading, reactive updates,
> and write flows.
>
> This guide is descriptive. Normative rules live in [../INVARIANTS.md](../INVARIANTS.md).

## 1) Why this guide exists

Taskly already has strong building blocks:

- BLoC-only presentation boundary
- session stream cache primitives
- domain-owned occurrence read semantics

The main inconsistency is not architecture direction, but screen-to-screen
composition shape. Some screens use a clear query-service pipeline, while others
bind domain services directly in the screen BLoC.

This guide standardizes one repeatable pattern that keeps reactive behavior
immediate and improves day-to-day DX.

## 2) Recommended app-wide pattern

Use this data pipeline for each screen:

```text
Widget/Page
  -> ScreenIntentBloc (writes, effects)
  -> ScreenFeedBloc (read state machine)
  -> ScreenQueryService (single derived stream)
  -> Session services/cache (when shared) + Domain read services
  -> Repository contracts
```

Key intent:

- Keep feed loading/retry/error behavior uniform.
- Keep writes explicit and separate from long-lived read subscriptions.
- Keep recurrence/date semantics in domain read services.

## 3) Role definitions

### 3.1 `ScreenFeedBloc`

Responsibilities:

- Start/retry read subscriptions (`restartable()`).
- Bind one derived stream via `emit.forEach` or `emit.onEach`.
- Expose a small state machine: `Loading`, `Loaded(data)`, `Error(message)`.

Do not:

- scatter multiple independent screen-level subscriptions if one composed stream
  is feasible.
- perform writes directly in the feed BLoC.

### 3.2 `ScreenIntentBloc`

Responsibilities:

- Interpret user intent for writes.
- Create and pass `OperationContext`.
- Emit UI effects (navigation/snackbar/dialog triggers).

Do not:

- own long-lived read subscriptions.

### 3.3 `ScreenQueryService`

Responsibilities:

- Compose streams into one screen-shaped stream.
- Apply presentation policy (scope, sorting, section grouping, lightweight
  shaping).
- Stay side-effect free (no writes, no navigation).

Do not:

- embed business semantics that belong in domain.

### 3.4 Session services/cache

Use session cache for cross-screen or repeatedly reused streams:

- values
- inbox counts
- shared project snapshots
- shared bounded scheduled windows

Keep highly screen-specific or range-heavy streams page-scoped unless there is
clear reuse.

## 4) Error and retry model

Use the same feed contract across screens:

- stream failures map to error state
- UI exposes explicit retry
- retry rebinds the read stream deterministically

Avoid terminal patterns that can freeze updates after an upstream error.

## 5) Recurrence read model

Two read modes are useful and should stay explicit:

1. Preview mode (projects/detail style)
- one representative next occurrence for recurring entities
- uses `OccurrenceReadService.watchTasksWithOccurrencePreview(...)`

2. Timeline mode (scheduled style)
- occurrence expansion over a date range
- uses scheduled occurrence orchestration (`ScheduledOccurrencesService`)

Do not collapse these modes into one service contract. They solve different
product questions and have different data costs.

## 6) Current code mapping (as of this guide)

### 6.1 My Day

Good alignment:

- `lib/presentation/screens/bloc/my_day_bloc.dart`
- `lib/presentation/screens/services/my_day_session_query_service.dart`
- `lib/presentation/screens/services/my_day_query_service.dart`

Notes:

- Pattern is close to target pipeline.
- Error continuity in `MyDayQueryService` should avoid terminal stalls.

### 6.2 Projects list

Good alignment:

- `lib/presentation/features/projects/bloc/projects_screen_bloc.dart`
- `lib/presentation/features/projects/bloc/projects_feed_bloc.dart`
- `lib/presentation/features/projects/services/projects_session_query_service.dart`

This is a reference implementation for split intent/feed concerns.

### 6.3 Scheduled timeline

Good alignment:

- `lib/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart`
- `lib/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart`
- `lib/presentation/features/scheduled/services/scheduled_session_query_service.dart`

Current shape:

- timeline binds range windows through the scheduled session query service.
- scheduled session query service keys cached streams by scope + range.
- near-horizon prewarm remains bounded.
- writes stay in `ScheduledScreenBloc` and use one bulk intent event:
  `ScheduledRescheduleEntitiesDeadlineRequested`.
- legacy split write events/effects were removed to keep one intent surface.

### 6.4 Project detail

Partial alignment:

- `lib/presentation/features/projects/bloc/project_overview_bloc.dart`
- `lib/presentation/features/projects/bloc/project_detail_bloc.dart`

Good:

- recurring task preview uses `OccurrenceReadService` with projects preview
  policy (correct for this screen purpose).

Needs cleanup:

- avoid manual refresh re-dispatch where reactive streams already cover updates.

## 7) Scheduled data strategy for larger datasets

For recurring entities, occurrence expansion cost is driven by:

- number of recurring tasks/projects in scope
- expansion horizon length
- number of active scopes (global/project/value)

Recommended strategy:

- keep one bounded "near horizon" prewarm (for fast tab open).
- use range-aware query keys for broader windows required by timeline scroll.
- avoid prewarming large arbitrary windows for all scopes.

Example key shape:

```text
scheduled:{scopeKind}:{scopeId}:{windowStart}:{windowEnd}
```

Use bounded buckets (for example month buckets) to keep cache cardinality
predictable.

## 8) Migration plan template (per screen)

1. Extract or create `*QueryService` that returns one derived stream.
2. Update feed BLoC to bind only that stream.
3. Keep writes in intent/actions BLoC and pass `OperationContext`.
4. Map stream errors to `Error` state with retry.
5. Add/adjust tests for:
   - initial loading
   - reactive update after write
   - transient stream error and retry

## 9) Checklist for new screens

- Use split BLoCs when reads and writes are both non-trivial.
- Prefer one derived stream per feed BLoC.
- Decide early: session-shared stream or page-scoped stream.
- Keep recurrence semantics in domain services.
- Standardize loading/error/retry states and event names.

## 10) Related docs

- Invariants: [../INVARIANTS.md](../INVARIANTS.md)
- BLoC guidelines: [BLOC_GUIDELINES.md](BLOC_GUIDELINES.md)
- Session stream cache: [SESSION_STREAM_CACHE.md](SESSION_STREAM_CACHE.md)
- Error handling: [ERROR_HANDLING_AND_FAILURES.md](ERROR_HANDLING_AND_FAILURES.md)
- Screen architecture: [SCREEN_ARCHITECTURE.md](SCREEN_ARCHITECTURE.md)
