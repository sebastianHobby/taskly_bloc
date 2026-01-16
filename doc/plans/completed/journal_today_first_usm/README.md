# Journal Today-first (USM) — Implementation Plan

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T23:37:02.6585320Z

## Purpose

Implement the accepted Journal UX direction (Today-first, mood-first, full-screen editor) as a standard Unified Screen Model screen (`standardScaffoldV1`), and lay the foundation for stats/insights (“this may help / may hurt”) without compromising the journaling-first experience.

## Phases

- Phase 01: Decision normalization + scope
- Phase 02: USM screen specs + module scaffolding
- Phase 03: Entry editor + Today logging loop
- Phase 04: Manage Trackers (archive/delete + outcome classification)
- Phase 05: Foundational journal stats + insight hooks

## Notes

- This plan intentionally keeps daily logging UX simple; outcome/factor classification lives in Manage Trackers (UX-026A).
- Test execution timing: follow repo guidance (do not run tests unless explicitly requested; recommend running the appropriate `flutter test` preset after implementation is complete).
