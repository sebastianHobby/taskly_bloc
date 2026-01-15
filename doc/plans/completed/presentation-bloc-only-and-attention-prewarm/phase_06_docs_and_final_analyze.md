# Phase 06 — Docs + Final Analyze Sweep

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T12:13:28.8573733Z (UTC)

## Outcome

- Architecture docs explicitly codify the “presentation is bloc-only” rule.
- Note: `flutter analyze` cleanup is deferred (out of scope for this plan completion).

## Work

1) Documentation updates
- Update `doc/architecture/README.md` (or add a dedicated doc) to state:
  - Widgets/pages should not call repositories or create repo streams.
  - Subscriptions are owned by BLoCs.
  - Allowed exceptions (narrow): ephemeral widget-only streams not related to data (animations/controllers), and already-cached UI-only streams like navigation badge streams.

2) Final analyzer sweep
- Out of scope: Run `flutter analyze` and fix **any** remaining analyzer errors/warnings.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Out of scope for this plan completion: fix **any** `flutter analyze` error or warning (regardless of whether it is related to the plan).
