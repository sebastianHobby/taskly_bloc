# Plan: Global action failure surfacing (single app-shell listener)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Goal
Make **one** app-shell/global listener responsible for surfacing all `ScreenActionsBloc` failures (SnackBars) across the authenticated app, so pages do not need to add their own listeners.

Additionally, **harden** the mechanism against:
- Navigation timing (action failure arrives during route transitions / page pop)
- Duplicate delivery (multiple failures in quick succession; repeated failures from rebuilds)

## Scope
In-scope:
- Provide `ScreenActionsBloc` once for the authenticated app shell (not per-page).
- Install a single failure listener that shows a localized friendly SnackBar.
- Ensure SnackBar presentation is **navigation-safe** (not dependent on a soon-to-dispose page context).
- Ensure SnackBar presentation is **globally deduped/throttled**.
- Remove/avoid duplicate listeners in pages that currently show SnackBars.

Out-of-scope (explicitly not in this plan unless later requested):
- UI/UX redesign of error components.
- Changing domain error types or introducing new domain-layer error mapping.
- Reworking action APIs (events/completers) beyond what’s needed for global wiring.

## Current baseline (observed)
- `ScreenActionsBloc` is currently created in multiple pages:
  - Unified system screens: `UnifiedScreenPageFromSpec`.
  - Entity detail screens: project/value unified detail pages.
- Failure surfacing exists at least in `UnifiedScreenPageFromSpec` (local listener).
- Authenticated app uses `MaterialApp.router` in `App` and a `ShellRoute` scaffold.

## Decision to lock in during this phase
Pick exactly one of the following architectures (A recommended):

### Option A (recommended): Global `ScreenActionsBloc` provided in `_AuthenticatedApp`
- Provide `BlocProvider<ScreenActionsBloc>` once, above `MaterialApp.router`.
- Use `MaterialApp.router(scaffoldMessengerKey: ...)` plus `builder: ...` to add a single `BlocListener` that renders SnackBars.

Hardening notes for A:
- Prefer `GlobalKey<ScaffoldMessengerState>` over `ScaffoldMessenger.of(context)`.
- Centralize dedupe/throttle policy in a small presenter/service.

Why A:
- Stable lifecycle: `_AuthenticatedApp` exists for the authenticated session.
- Listener is in a predictable place and uses `ScaffoldMessenger` safely.
- Avoids `ShellRoute` rebuild pitfalls (accidental re-creation).

### Option B: Provide + listen inside `ShellRoute` scaffold
- Put global provider/listener around `ScaffoldWithNestedNavigation`.

Why not B (likely):
- `ShellRoute` builder can rebuild; easy to accidentally recreate bloc.
- Harder to guarantee a stable `ScaffoldMessenger` context.

### Option C: Global “action failure bus” service
- Keep per-page blocs, but forward failures to a global service/stream.

Why not C (likely):
- More moving parts; higher coupling and harder to reason about.

## Acceptance criteria (end of phase)
- Architecture choice is committed in writing (Option A/B/C) and rationale recorded.
- Target insertion point is identified:
  - where `ScreenActionsBloc` will be provided
  - where the global listener will be attached
- A migration map is listed for each existing provider/listener location that must be updated/removed.
- A hardening policy is specified:
  - Dedupe key (recommended: final displayed message string)
  - Dedupe window (recommended: 1500–2500ms)
  - Whether to queue or replace SnackBars (recommended: replace + hide current)
  - Delivery strategy during navigation transitions (recommended: use global messenger key + post-frame)

## Implementation sketch (for Option A)
- Add `BlocProvider<ScreenActionsBloc>` in the authenticated app tree (near where other app-wide providers live).
- Add a `GlobalKey<ScaffoldMessengerState>` and pass it to `MaterialApp.router(scaffoldMessengerKey: ...)`.
- In `MaterialApp.router(builder: ...)`, wrap the routed `child` with a `BlocListener<ScreenActionsBloc, ScreenActionsState>`.
- The listener uses:
  - `friendlyErrorMessageForUi(error, context.l10n)` when error is present
  - fallback to `state.message`
- The listener delegates SnackBar display to a presenter that uses `scaffoldMessengerKey.currentState`.
- The presenter applies dedupe/throttle, and schedules display post-frame when needed.
- Ensure no duplicate listeners remain in page widgets.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately with a completion summary and date completed (UTC).
