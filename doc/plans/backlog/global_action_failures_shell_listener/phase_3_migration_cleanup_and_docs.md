# Phase 3: Migrate call sites, remove duplicates, harden

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Goal
Finish the migration so pages do not create their own `ScreenActionsBloc` (unless explicitly required), remove any local listeners that would duplicate SnackBars, and update docs to reflect the new “single listener” rule.

## Steps
1) Remove per-page `ScreenActionsBloc` providers where safe
- Update entity detail pages that currently create a `ScreenActionsBloc` to rely on the global provider.
- Ensure widgets still dispatch events via `context.read<ScreenActionsBloc>()`.

2) Remove local failure listeners that would duplicate behavior
- Remove any `BlocListener<ScreenActionsBloc, ...>` used only for SnackBars inside page widgets.
- Keep local listeners only if they are doing additional page-specific handling (and ensure they don’t show SnackBars).

3) Ensure no new duplicates can creep back in
- Add a small lint-like guardrail in docs (and optionally a code pattern) that makes it obvious where action failure presentation lives.
- Optional: expose the presenter as a single widget used only at app shell level.

4) Add guardrails
- Add an invariant to the USM architecture doc: “action failures are surfaced by the app shell; screens must not show SnackBars for `ScreenActionsBloc` failures.”
- Optional hardening (if needed): introduce a small `ActionFailureSnackBarPresenter` widget so the pattern is reusable/testable.

5) Validation
- Run `flutter analyze` and ensure it is clean.
- Manual QA checks:
  - Trigger action failures from: unified system screens and entity detail pages.
  - Confirm single SnackBar per failure.
  - Confirm failures still logged.
  - Trigger failures while navigating (e.g., dispatch action then immediately pop/route-change) and confirm SnackBar still appears.
  - Trigger repeated failures rapidly and confirm dedupe/throttle behavior.

## Acceptance criteria
- Unified system screens show SnackBars via the global listener only.
- Project/value unified detail pages show SnackBars via the global listener.
- No duplicated SnackBars.
- Documentation updated to reflect the global policy.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- In this last phase, fix ANY `flutter analyze` error or warning (regardless of whether it is related to the plan).
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately with a completion summary and date completed (UTC).
