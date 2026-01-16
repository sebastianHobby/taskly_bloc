# Phase 05 — Foundational journal stats + “this may help / hurt” hooks

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T23:37:02.6585320Z

## Goal

Un-stub the journal portions of analytics enough to support basic trends and correlations:
- Mood trend and distribution
- Tracker trend
- Mood vs tracker correlation

Use the outcome/factor classification (`isOutcome`) only to improve interpretation and UX copy (do not require it in the logging loop).

## Scope

- Implement `JournalRepositoryContract` methods used by analytics:
  - `getDailyMoodAverages`
  - `getTrackerValues`
- Update `AnalyticsServiceImpl` to return real data for:
  - `getMoodTrend`, `getMoodDistribution`, `getMoodSummary`
  - `getTrackerTrend`
  - `calculateCorrelation` for mood vs tracker and tracker vs tracker (as feasible)

## Implementation tasks

1) Journal repository reads
- Read mood values from tracker projections (prefer `tracker_state_day` / `tracker_state_entry`) rather than raw events when possible.
- Ensure date bucketing rules are explicit (UTC vs local date policy).

2) Analytics service
- Replace “being rebuilt” stubs with real computations.
- Ensure correlation outputs include:
  - sample size
  - direction and strength
  - an explanation string suitable for UX (“may help / may hurt”) that respects `higherIsBetter` when available.

3) Outcome/factor interpretation (UX)
- When generating insights:
  - treat outcomes as potential targets
  - treat factors as potential sources
- If `higherIsBetter` is null, fall back to neutral phrasing.

## Acceptance criteria

- Analytics no longer returns empty mood/tracker trend data.
- Correlation APIs return non-empty results when data exists.
- Insight copy is directionally consistent and avoids overclaiming.

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- This is the last phase: fix ANY `flutter analyze` error or warning (regardless of whether it is related to the phase).
- When the phase is complete, update:
  - `Last updated at:` (UTC)
  - `Completed at:` (UTC)
  - A short summary of what changed

## Completion

Completed at: 2026-01-15T23:37:02.6585320Z
Summary:
- Implemented `JournalRepositoryImpl.getDailyMoodAverages` and `getTrackerValues` by aggregating tracker events by UTC day.
- Replaced analytics stubs in `AnalyticsServiceImpl` with real mood/tracker trends, mood distribution/summary, mood↔tracker correlations, and mood↔entity correlations.
