# Taskly — BLoC Guidelines

> Audience: developers
>
> Scope: how we write BLoCs in Taskly so they are safe, consistent, and aligned
> with the architecture invariants.
>
> This document contains a mix of:
> - **Normative rules** (hard requirements): must follow.
> - **Guidelines** (strong recommendations): default approach unless there is a
>   clear reason not to.

## 0) Why this exists

Taskly is **BLoC-only** for application state. The most common failure mode in
stream-backed screens is calling `emit(...)` outside of the active event
handler lifecycle ("emit was called after an event handler completed normally").

This doc standardizes patterns that:
- keep stream subscriptions inside the event-handler lifecycle,
- make cancellation and retries deterministic,
- prevent transient stream failures from permanently breaking UI.

## 1) Normative rules (hard requirements)

### 1.1 UI reads are BLoC-owned

Widgets/pages must not:
- call repositories/services directly
- subscribe to domain/data streams directly

BLoCs own subscriptions and expose widget-ready state.

See: `doc/architecture/ARCHITECTURE_INVARIANTS.md`.

### 1.2 No `emit(...)` after the handler completes

**Rule:** Do not call `emit(...)` from any async callback that may outlive the
current event handler.

This includes:
- stream `.listen((data) { emit(...); })` callbacks,
- `future.then((_) => emit(...))` / `whenComplete(...)` patterns,
- timers that call `emit(...)`.

**Allowed patterns:**
- Bind streams using `await emit.forEach(...)` or `await emit.onEach(...)`.
- If you `await` any async work and then need to `emit`, guard with:
  `if (emit.isDone) return;`.

### 1.3 Retries must be deterministic and cancel in-flight work

**Rule:** For events which (re)start watchers (ex: `Started`, `RetryRequested`,
`RefreshRequested`), the handler must be cancellation-safe.

Default approach:
- use `bloc_concurrency.restartable()` for the handler transformer, and
- bind watchers via `emit.onEach`/`emit.forEach` so cancellation stops emissions.

### 1.4 Stream failures must not permanently kill UI

**Rule:** A transient stream failure must map into an explicit error state.

- Do not allow a stream error to terminate a BLoC without producing a usable
  state for the UI.
- Provide an explicit retry event and renderable error state.

## 2) Standard BLoC shapes

These are guidance-level patterns.

### 2.1 "Feed / Watch" BLoC (stream-driven screen)

Use this for screens that are derived from one or more reactive streams.

Guidelines:
- Keep state as a small state machine:
  - `Loading`
  - `Loaded(data)`
  - `Error(message)`
- Bind streams in `Started` and re-bind in `RetryRequested`.
- Prefer `restartable()` for start/retry.
- Prefer `emit.forEach` when you can map stream events directly to a state.
- Prefer `emit.onEach` when you need to update cached fields before emitting.

### 2.2 "Command / Write" BLoC

Use this for user-initiated writes.

Guidelines:
- Create an `OperationContext` at the user intent boundary (in the handler).
- Call a domain use-case (or equivalent write facade) and pass the context.
- Map failures into deterministic error states; do not leak raw exceptions as a
  normal control flow mechanism.

For recurrence (tasks/projects with RRULEs):

- Do not compute or “guess” occurrence keys (dates) in UI code for writes.
- Prefer calling a domain command service that resolves the target occurrence
  (for example "complete next occurrence") and then performs the mutation.
- If a screen needs to *display* a single representative occurrence in a
  non-date feed, use a shared domain selector/helper rather than duplicating
  selection logic across BLoCs.

### 2.3 "Gate" BLoC (routing / readiness)

Use this when a screen depends on app readiness, auth state, or feature flags.

Guidelines:
- Keep gate states small and explicit.
- Avoid mixing gate logic into feed BLoCs.

## 3) Using RxDart (where it helps)

RxDart is allowed and recommended when it reduces complexity for multi-stream
screens.

Use cases:
- `combineLatest` to compute derived view models from multiple streams.
- `switchMap` to rebind dependent streams (ex: `dayKey$` -> `allocatedIds$`).
- `distinct` to prevent redundant recomputation.

Guidelines:
- Prefer one derived stream and a single `emit.forEach(...)` binding when the
  screen is purely derived.
- Avoid using `Subject`s unless you truly need imperative injection.

## 4) Event concurrency policy (bloc_concurrency)

Use event transformers explicitly for handlers that start async work.

Recommended defaults:
- `Started` / `RetryRequested` / `RefreshRequested`: `restartable()`
- Pagination / "Load more": `droppable()`
- Writes where ordering matters: `sequential()`

## 5) Checklist for code review

- No `.listen(... emit(...))` patterns in BLoCs.
- Stream bindings are done via `emit.forEach` / `emit.onEach`.
- If a handler does `await ...` and then emits, it checks `emit.isDone`.
- Start/retry handlers use `restartable()` unless justified otherwise.
- Errors map into state + retry exists.
- Writes create and pass `OperationContext`.
