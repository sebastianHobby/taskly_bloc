# Plan: Presentation BLoC-only + Attention Prewarm

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T12:13:28.8573733Z (UTC)

## Goal

1) Enforce the architecture rule: **UI widgets do not call repositories or create repository streams**. UI should talk to **BLoCs only**.
2) Improve perceived performance for Attention (Inbox + banner sections) by adding **engine-level caching** and **boot-time prewarming**.

## Non-goals

- No large UX redesign.
- No test suite changes unless explicitly requested.
- No repo-wide cleanup beyond what this plan touches.

## Allocation trigger / “prewarm” decision

Allocation is already effectively “prewarmed” at boot:

- `AllocationSnapshotCoordinator.start()` is called during bootstrap.
- It subscribes to allocation inputs (`AllocationOrchestrator.combineStreams()`) and triggers allocation computation.
- When applicable, it runs `AllocationOrchestrator.watchAllocation().first`, which also persists today’s snapshot.

Because of that, an additional allocation prewarm stream is usually redundant.

Decision gate:

- If My Day is still slow because snapshot is missing on first open, consider a minimal change: schedule a `requestRefreshNow(...)` after coordinator start (only once inputs exist).

## Phases

- Phase 01: Baseline + metrics + confirm allocation behavior
- Phase 02: Attention cached engine + boot prewarm + Inbox gating fix
- Phase 03: JournalToday + AddLogSheet refactor to BLoC
- Phase 04: JournalTrackers + MyDay gate refactor to BLoC
- Phase 05: AttentionRules + Settings maintenance refactor to BLoC
- Phase 06: Docs + final `flutter analyze` sweep

## Completion note

This plan is considered complete for the scope implemented (Phases 02–05).

Deferred as out-of-scope follow-ups:

- Navigation badge streams: remaining `StreamBuilder` usage and repository-backed badge streams in navigation chrome.
- Final analyzer sweep: `flutter analyze` cleanup is deferred to a dedicated follow-up.
