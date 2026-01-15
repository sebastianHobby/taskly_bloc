# Phase 2: Implement global provider + single listener

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Goal
Implement the chosen approach (expected Option A) so there is exactly **one** app-wide listener for `ScreenActionsBloc` failures in the authenticated app, with:
- navigation-safe SnackBar delivery
- global dedupe/throttle

## Steps
1) Provide a single `ScreenActionsBloc` for authenticated app
- Add `BlocProvider<ScreenActionsBloc>` at the authenticated app root (above `MaterialApp.router`).
- Instantiate with `EntityActionService` via `getIt`.

2) Add a global `ScaffoldMessengerKey`
- Create a `GlobalKey<ScaffoldMessengerState>` that is owned by the authenticated app shell.
- Pass it to `MaterialApp.router(scaffoldMessengerKey: messengerKey, ...)`.

3) Add an `ActionFailureSnackBarPresenter`
- Implement a small presentation-layer helper that:
  - accepts the messenger key
  - applies dedupe/throttle (see below)
  - safely schedules SnackBars post-frame

Recommended dedupe policy:
- Dedupe key: final displayed message string
- Window: 2 seconds
- Behavior: replace (call `hideCurrentSnackBar()` then show)

4) Add the global SnackBar listener
- Wrap the routed `child` in `MaterialApp.router(builder: ...)` with `BlocListener<ScreenActionsBloc, ScreenActionsState>`.
- Trigger only on `ScreenActionsFailureState`.
- Show SnackBar text using:
  - `friendlyErrorMessageForUi(state.error!, context.l10n)` when `error != null`
  - otherwise `state.message`

Implementation note:
- The listener should call the presenter (not `ScaffoldMessenger.of(context)` directly).

5) Ensure safety and UX consistency
- Avoid stacking SnackBars for rapid failures (handled by presenter).
- Ensure errors still show even if the originating page was popped (handled by global messenger key + post-frame scheduling).

## Acceptance criteria
- In authenticated flows, any `ScreenActionsFailureState` results in exactly one SnackBar.
- No page-level listener is required for action failures.
- No duplicate SnackBars appear on unified system screens.
- During navigation (e.g., failure then immediate pop), the SnackBar still appears reliably.
- When the same failure is emitted repeatedly in a short window, only one SnackBar is shown.

## Notes / pitfalls to verify
- Ensure `ScreenActionsBloc` is not recreated on navigation changes.
- Ensure listener is not attached multiple times (e.g., nested `builder` wrappers).
- Ensure the presenter is not recreated per rebuild in a way that defeats dedupe.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately with a completion summary and date completed (UTC).
