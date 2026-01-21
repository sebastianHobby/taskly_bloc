# Taskly — BLoC Guidelines

> Audience: developers
>
> Scope: how we write BLoCs in Taskly so they are safe, consistent, and aligned
> with the architecture invariants.
>
> This guide is descriptive. Architecture invariants (layering/boundaries) live
> in: [../INVARIANTS.md](../INVARIANTS.md)

## 0) Why this exists

Taskly is **BLoC-only** for application state. The most common failure mode in
stream-backed screens is calling `emit(...)` outside of the active event
handler lifecycle ("emit was called after an event handler completed normally").

This doc standardizes patterns that:
- keep stream subscriptions inside the event-handler lifecycle,
- make cancellation and retries deterministic,
- prevent transient stream failures from permanently breaking UI.

## 1) Core constraints

### 1.1 UI reads are BLoC-owned

This is an architecture invariant:

- [../INVARIANTS.md](../INVARIANTS.md#2-presentation-boundary-bloc-only)

### 1.2 No `emit(...)` after the handler completes

Do not call `emit(...)` from any async callback that may outlive the
current event handler.

This includes:
- stream `.listen((data) { emit(...); })` callbacks,
- `future.then((_) => emit(...))` / `whenComplete(...)` patterns,
- timers that call `emit(...)`.

**Allowed patterns:**
- Bind streams using `await emit.forEach(...)` or `await emit.onEach(...)`.
- If you `await` any async work and then need to `emit`, guard with:
  `if (emit.isDone) return;`.

### 1.3 Retries should be deterministic and cancel in-flight work

For events which (re)start watchers (ex: `Started`, `RetryRequested`,
`RefreshRequested`), the handler needs to be cancellation-safe.

Default approach:
- use `bloc_concurrency.restartable()` for the handler transformer, and
- bind watchers via `emit.onEach`/`emit.forEach` so cancellation stops emissions.

### 1.4 Stream failures should not permanently kill UI

A transient stream failure should map into an explicit error state.

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

### 2.4 Thin orchestrators and where logic belongs

Taskly BLoCs should be **thin orchestrators** by default.

BLoCs own:

- Interpreting user intent (events) and creating `OperationContext` for writes.
- Binding/unbinding streams safely (`emit.forEach` / `emit.onEach`).
- Mapping domain outputs into widget-ready state (small state machines).
- Presentation side-effects (navigation, snackbars/dialog triggers) where
  lifecycle is explicit.

Domain owns:

- Business semantics that are consistent across screens.
- Use-cases / write facades (atomic mutations, recurrence targeting, validation).
- View-neutral selectors/pure functions that are reusable across screens.

Repeatable *screen-shaped* logic belongs in **presentation query services**
(for example `*QueryService`, `*ScreenModelBuilder`):

- Combine multiple streams into one derived stream for a screen.
- Apply presentation policy (sectioning, debounce, paging mechanics, empty/error
  shaping).
- Remain side-effect free (no writes, no routing).

Anti-goal:

- Do not push screen models ("AnytimeScreenModel", tile models, UI copy) into
  Domain. See: [../INVARIANTS.md](../INVARIANTS.md#011-domain-outputs-must-be-view-neutral-strict)

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

### 3.1 Fan-out (share upstream triggers)

If one upstream stream is used by multiple downstream subscriptions, it needs to be
**shareable**.

Common footgun:
- A single-subscription stream (the default for most composed streams) is
  re-used in multiple `switchMap`/`combineLatest` chains.
- Each chain subscribes independently.
- Runtime crash: `Bad state: Stream has already been listened to.`

Guidelines:
- If you use an upstream trigger in more than one derived stream, make it a
  broadcast/shared stream using RxDart (for example `share()`/`shareReplay(...)`
  or `shareValue()` when you explicitly want `ValueStream` semantics).
- Prefer `shareReplay(maxSize: 1)` when you need the latest value for late
  subscribers but do not want `ValueStream` behavior.
- Prefer keeping the fan-out inside a single derived stream when reasonable
  (compute a single view model stream and bind once with `emit.forEach`).

#### Picking a sharing operator (trade-offs)

- `share()`
  - Pros: simplest; turns a single-subscription stream into a broadcast stream.
  - Cons: does not replay the last value; late subscribers may miss the current
    value and wait for the next event.

- `shareReplay(maxSize: 1)`
  - Pros: safe fan-out + late subscribers immediately get the latest value.
  - Cons: retains the last event; be mindful when the value is large.

- `shareValue()` (creates a `ValueStream`)
  - Pros: always has a “current value” concept; convenient for UI/state-like
    streams.
  - Cons: stronger semantics than you often need; can encourage accidental
    reliance on synchronous `value` access and can keep values alive longer.

Default preference:
- Use `shareReplay(maxSize: 1)` for derived trigger streams that multiple chains
  subscribe to.
- Use `shareValue()` only when you explicitly want `ValueStream` semantics.

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
- Any upstream stream fanned out to multiple derived streams is shared/broadcast
  (no multi-listen single-subscription crashes).
- Start/retry handlers use `restartable()` unless justified otherwise.
- Errors map into state + retry exists.
- Writes create and pass `OperationContext`.
- Repeated reactive composition is extracted into a presentation query service
  (not duplicated across BLoCs and not pushed into Domain).
