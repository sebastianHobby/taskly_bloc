# Phase 01 — Baseline, Success Metrics, and Guardrails

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T10:45:52.1300375Z (UTC)

## Outcome

- Establish measurable success criteria and a repeatable manual verification loop.
- Decide whether allocation needs any additional prewarm beyond the existing coordinator.

## Work

1) Record baseline UX timings (manual)
   - Attention: cold-start open, warm-start open, switch Action/Review.
   - Attention banner: open a screen with the banner; note time-to-first-content.
   - My Day: cold-start open; note whether allocation section shows quickly and whether it relies on snapshot or fallback.

2) Record baseline analyzer state
   - Capture current `flutter analyze` output.
   - Do **not** fix unrelated warnings in this phase; just note them.

3) Confirm allocation boot behavior (no code changes unless required)
   - Verify `AllocationSnapshotCoordinator.start()` is called during bootstrap and that it performs `watchAllocation().first` when inputs are ready.
   - Decision gate:
     - If My Day is fast and snapshot exists early enough: **no extra allocation prewarm**.
     - If My Day is slow because snapshot is missing on first open: consider a minimal boot-time `requestRefreshNow(inputsChanged)` scheduled after coordinator start.

## Acceptance criteria

- A written baseline (in this plan folder or as notes in PR description).
- A clear “allocation prewarm needed?” decision with rationale.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Fix only analyzer issues caused by Phase 01 changes (ideally none).
