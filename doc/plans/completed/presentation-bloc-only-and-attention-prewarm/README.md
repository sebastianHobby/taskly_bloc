# Plan: Presentation BLoC-only + Attention Prewarm

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T12:13:28.8573733Z (UTC)

This plan is tracked in the phase files.

- Start here: [phase_00_overview.md](phase_00_overview.md)
- Then follow phases 01–06 in order.

- `AllocationSnapshotCoordinator.start()` is called during bootstrap and subscribes to allocation inputs.
- It triggers `AllocationOrchestrator.watchAllocation().first` (debounced and only when focus mode is selected and inputs are non-empty), which persists the day’s allocation snapshot.

Because of that, an additional “allocation prewarm stream” is usually redundant. The plan below includes a checkpoint to verify cold-start behavior for My Day; only if My Day is still slow/empty due to missing snapshot on first open will we consider an extra `requestRefreshNow()` after coordinator start.

## Phases

- Phase 01: Baseline + architecture guardrails
- Phase 02: Attention cached engine + boot prewarm + inbox gating fix
- Phase 03: JournalToday + AddLogSheet refactors (BLoC)
- Phase 04: JournalTrackers + MyDay gate refactors
- Phase 05: AttentionRules + Settings maintenance refactors
- Phase 06: Docs + final `flutter analyze` sweep

## Status

Completed for the scope implemented in Phases 02–05 (Attention caching/prewarm and the targeted BLoC-only refactors).

## Explicitly out of scope (deferred follow-ups)

- Navigation badge streams: `StreamBuilder` usage in navigation chrome (badges) and the underlying repository-backed badge streams are not refactored in this plan.
- `flutter analyze` cleanup: analyzer is not expected to be clean as part of this plan completion; a dedicated follow-up should address the remaining analyzer issues.
