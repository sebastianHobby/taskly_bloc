# Phase 04 — JournalTrackers + My Day Gate (BLoC-only UI)

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T10:45:52.1300375Z (UTC)

## Outcome

- Remove direct repository access and StreamBuilders from:
  - `JournalTrackersPage`
  - `MyDayFocusModeRequiredPage`

## Work

1) `JournalTrackersCubit`
- Watch tracker definitions + preferences.
- Expose intents: `createTracker(name)`, `savePreference(pref)`.
- UI becomes bloc-driven.

2) `MyDayGateBloc`
- Watch allocation settings + values list.
- Compute derived UI model (needsFocusModeSetup, needsValuesSetup, CTA label/icon, description text).
- UI becomes bloc-driven.

## Allocation prewarm note

Do not introduce a new allocation prewarm unless Phase 01 found evidence it’s needed.
- Allocation snapshots are already kept warm by `AllocationSnapshotCoordinator` started in bootstrap.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Ensure any analyzer errors/warnings caused by this phase are fixed by the end of the phase.
